-- ========================================================
-- 1. KÍCH HOẠT EXTENSION POSTGIS ĐỂ TÍNH TOÁN TỌA ĐỘ BÁN KÍNH
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

-- Bật RLS cho profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mọi người đều có thể đọc profile công khai"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Người dùng tự cập nhật profile của mình"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

-- Trigger tự động tạo profile khi người dùng đăng ký Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'role', 'driver')
    );
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
    -- Tọa độ địa lý dùng PostGIS
    location GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    
    -- Giá niêm yết (VND)
    price_per_hour INTEGER DEFAULT 10000,
    price_per_turn INTEGER DEFAULT 20000,
    price_overnight INTEGER DEFAULT 50000,
    
    -- Sức chứa & Tình trạng
    total_capacity INTEGER DEFAULT 30,
    current_status TEXT NOT NULL DEFAULT 'available' CHECK (current_status IN ('available', 'nearly_full', 'full', 'closed')),
    status_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status_updated_by UUID REFERENCES auth.users(id),
    
    -- Giờ hoạt động
    open_time TEXT DEFAULT '06:00',
    close_time TEXT DEFAULT '22:00',
    is_24h BOOLEAN DEFAULT false,
    
    -- Tiện ích
    has_roof BOOLEAN DEFAULT false,          -- Mái che
    has_ev_charging BOOLEAN DEFAULT false,   -- Trụ sạc xe điện
    has_security BOOLEAN DEFAULT true,       -- Bảo vệ trực
    has_camera BOOLEAN DEFAULT true,         -- Camera an ninh
    
    phone_number TEXT,
    image_url TEXT,
    owner_id UUID REFERENCES auth.users(id),  -- Chủ bãi phụ trách
    is_approved BOOLEAN DEFAULT true,        -- Admin đã duyệt hay chưa
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index không gian để tìm bãi xe theo bán kính siêu tốc
CREATE INDEX IF NOT EXISTS idx_parking_lots_location ON public.parking_lots USING GIST (location);

-- Bật RLS cho parking_lots
ALTER TABLE public.parking_lots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ai đã đăng nhập cũng đọc được bãi xe đã duyệt"
    ON public.parking_lots FOR SELECT
    TO authenticated
    USING (is_approved = true OR auth.uid() = owner_id);

CREATE POLICY "Chủ bãi hoặc Admin có thể cập nhật thông tin bãi xe"
    ON public.parking_lots FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = owner_id 
        OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Tài xế có thể đề xuất bãi xe mới (chờ duyệt)"
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

CREATE POLICY "Người dùng đọc được báo cáo"
    ON public.reports FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Người dùng tạo báo cáo"
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

CREATE POLICY "Người dùng quản lý bãi yêu thích của mình"
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

CREATE POLICY "Người dùng quản lý vị trí đỗ xe của mình"
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

-- ========================================================
-- 8. NẠP DỮ LIỆU MẪU THỰC TẾ (10 BÃI XE NINH KIỀU, CẦN THƠ)
-- ========================================================
INSERT INTO public.parking_lots (
    name, address, district, city, latitude, longitude,
    price_per_hour, price_per_turn, price_overnight,
    total_capacity, current_status, open_time, close_time, is_24h,
    has_roof, has_ev_charging, has_security, has_camera,
    phone_number, image_url, is_approved
) VALUES
(
    'Bãi đỗ xe Bến Ninh Kiều',
    'Số 2 Đường Hai Bà Trưng, P. Tân An, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0336, 105.7876,
    15000, 30000, 60000,
    50, 'available', '06:00', '23:30', false,
    false, false, true, true,
    '02923812345', 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi đỗ xe TTTM Sense City Cần Thơ',
    'Số 1 Đại lộ Hòa Bình, P. Tân An, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0345, 105.7842,
    10000, 25000, 50000,
    80, 'nearly_full', '08:00', '22:00', false,
    true, true, true, true,
    '02923768888', 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi giữ xe Vincom Plaza Xuân Khánh',
    '209 Đường 30 Tháng 4, P. Xuân Khánh, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0274, 105.7725,
    10000, 20000, 50000,
    120, 'available', '00:00', '23:59', true,
    true, true, true, true,
    '02923838888', 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi đỗ xe Vincom Plaza Hùng Vương',
    'Số 2 Hùng Vương, P. Thới Bình, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0438, 105.7820,
    10000, 20000, 45000,
    70, 'available', '08:30', '22:00', false,
    true, true, true, true,
    '02923689999', 'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi đỗ xe Chợ Đêm Cần Thơ / Hoa Viên Ninh Kiều',
    'Đường Ngô Quyền (gần Bến Phà Cũ), P. Tân An, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0352, 105.7865,
    15000, 30000, 70000,
    35, 'full', '17:00', '02:00', false,
    false, false, true, true,
    '0908123456', 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi giữ xe Bệnh viện Đa khoa TP Cần Thơ',
    'Số 4 Châu Văn Liêm, P. An Lạc, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0315, 105.7828,
    10000, 20000, 40000,
    40, 'nearly_full', '00:00', '23:59', true,
    true, false, true, true,
    '02923821235', 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi đỗ xe Sân vận động Cần Thơ (Khu Bãi Cát)',
    'Đường Lê Lợi, P. Cái Khế, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0475, 105.7852,
    10000, 20000, 40000,
    200, 'available', '00:00', '23:59', true,
    false, false, true, true,
    '0939112233', 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi giữ xe Công viên Sông Hậu',
    'Đường Sông Hậu, P. Cái Khế, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0520, 105.7885,
    10000, 20000, 50000,
    60, 'available', '06:00', '23:00', false,
    false, false, true, true,
    '0918776655', 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi đỗ xe Bến xe Khách Cần Thơ Cũ',
    'Đường Nguyễn Trãi, P. Cái Khế, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0410, 105.7790,
    10000, 20000, 40000,
    45, 'available', '05:00', '22:00', false,
    true, false, true, true,
    '02923832123', 'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?auto=format&fit=crop&w=600&q=80', true
),
(
    'Bãi đỗ xe Chợ Cổ Cần Thơ (Nhà Lồng)',
    'Đường Hai Bà Trưng, P. Tân An, Q. Ninh Kiều',
    'Ninh Kiều', 'Cần Thơ',
    10.0340, 105.7882,
    15000, 30000, 60000,
    25, 'nearly_full', '06:00', '22:00', false,
    false, false, true, true,
    '0907998877', 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=600&q=80', true
);
