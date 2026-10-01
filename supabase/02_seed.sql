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
