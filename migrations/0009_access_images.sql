-- ==========================================================
-- AAA Migration 0009 : รูปจากกล้อง ณ เวลาที่เกิด event + บ้านที่เกี่ยวข้อง
--   ไฟล์อยู่ใน R2 bucket aaa-images (private, ลบอัตโนมัติ 90 วัน) เก็บแค่ key ใน DB
--   key: <project_id>/<YYYY-MM-DD>/<event_id>-scene.jpg / -plate.jpg
--   house_id = บ้านที่เกี่ยวข้องกับ event (รู้ตัวตนเมื่อไรก็ผูก แม้ผลเป็น NO) NULL = ไม่รู้จัก / งานส่วนกลาง
-- ==========================================================

ALTER TABLE tb_access_log ADD COLUMN house_id TEXT;
ALTER TABLE tb_access_log ADD COLUMN plate_image_key TEXT;
-- image_url (มีตั้งแต่ 0001) = key ของรูปเต็มฉาก (scene)
CREATE INDEX IX_tb_access_log_house_date ON tb_access_log(house_id, timestamp);
