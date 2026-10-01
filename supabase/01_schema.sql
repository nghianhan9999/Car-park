-- ========================================================
-- 1. KÍCH HOẠT EXTENSION POSTGIS
-- ========================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- ========================================================
-- 2. BẢNG PROFILES (PHÂN QUYỀN: driver, owner, admin)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    phone_number TEXT,
    role TEXT NOT NULL DEFAULT 'driver' CHECK (role IN ('driver', 'owner', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mọi người đều có thể đọc profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Người dùng tự cập nhật profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

-- Trigger tự động tạo profile khi đăng ký tài khoản
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'role', 'driver')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================================
-- 3. BẢNG PARKING_LOTS (DANH SÁCH BÃI ĐỖ XE)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.parking_lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    district TEXT NOT NULL DEFAULT 'Ninh Kiều',
    city TEXT NOT NULL DEFAULT 'Cần Thơ',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    
    price_per_hour INTEGER DEFAULT 10000,
    price_per_turn INTEGER DEFAULT 20000,
    price_overnight INTEGER DEFAULT 50000,
    
    total_capacity INTEGER DEFAULT 30,
    current_status TEXT NOT NULL DEFAULT 'available' CHECK (current_status IN ('available', 'nearly_full', 'full', 'closed')),
    status_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status_updated_by UUID REFERENCES auth.users(id),
    
    open_time TEXT DEFAULT '06:00',
    close_time TEXT DEFAULT '22:00',
    is_24h BOOLEAN DEFAULT false,
    
    has_roof BOOLEAN DEFAULT false,
    has_ev_charging BOOLEAN DEFAULT false,
    has_security BOOLEAN DEFAULT true,
    has_camera BOOLEAN DEFAULT true,
    
    phone_number TEXT,
    image_url TEXT,
    owner_id UUID REFERENCES auth.users(id),
    is_approved BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_parking_lots_location ON public.parking_lots USING GIST (location);

ALTER TABLE public.parking_lots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Xem bãi xe đã duyệt"
    ON public.parking_lots FOR SELECT
    TO authenticated
    USING (is_approved = true OR auth.uid() = owner_id);

CREATE POLICY "Chủ bãi hoặc Admin cập nhật bãi xe"
    ON public.parking_lots FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = owner_id 
        OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Đề xuất bãi xe mới"
    ON public.parking_lots FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ========================================================
-- 4. BẢNG REPORTS (BÁO CÁO CỘNG ĐỒNG)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id UUID NOT NULL REFERENCES public.parking_lots(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    report_type TEXT NOT NULL CHECK (report_type IN ('full', 'available', 'wrong_price', 'closed', 'other')),
    reported_price INTEGER,
    notes TEXT,
    is_reviewed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Xem báo cáo"
    ON public.reports FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tạo báo cáo"
    ON public.reports FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin xử lý báo cáo"
    ON public.reports FOR UPDATE
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ========================================================
-- 5. BẢNG USER_FAVORITES & SAVED_PARKED_LOCATIONS
-- ========================================================
CREATE TABLE IF NOT EXISTS public.user_favorites (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lot_id UUID REFERENCES public.parking_lots(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, lot_id)
);

ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Quản lý bãi yêu thích"
    ON public.user_favorites FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.saved_parked_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    note TEXT,
    lot_name TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    parked_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.saved_parked_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Quản lý vị trí đỗ xe"
    ON public.saved_parked_locations FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ========================================================
-- 6. HÀM RPC TÌM BÃI ĐỖ XE THEO BÁN KÍNH (POSTGIS)
-- ========================================================
CREATE OR REPLACE FUNCTION public.get_nearby_parking_lots(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 10000
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    address TEXT,
    district TEXT,
    city TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    price_per_hour INTEGER,
    price_per_turn INTEGER,
    price_overnight INTEGER,
    total_capacity INTEGER,
    current_status TEXT,
    status_updated_at TIMESTAMPTZ,
    open_time TEXT,
    close_time TEXT,
    is_24h BOOLEAN,
    has_roof BOOLEAN,
    has_ev_charging BOOLEAN,
    has_security BOOLEAN,
    has_camera BOOLEAN,
    phone_number TEXT,
    image_url TEXT,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.address,
        p.district,
        p.city,
        p.latitude,
        p.longitude,
        p.price_per_hour,
        p.price_per_turn,
        p.price_overnight,
        p.total_capacity,
        p.current_status,
        p.status_updated_at,
        p.open_time,
        p.close_time,
        p.is_24h,
        p.has_roof,
        p.has_ev_charging,
        p.has_security,
        p.has_camera,
        p.phone_number,
        p.image_url,
        ST_Distance(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance_meters
    FROM public.parking_lots p
    WHERE p.is_approved = true
      AND ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================================
-- 7. BẬT REALTIME CHO BẢNG PARKING_LOTS
-- ========================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'parking_lots'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.parking_lots;
  END IF;
END $$;
