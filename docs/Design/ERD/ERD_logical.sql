-- ERD logic (mức nghiệp vụ) — suy ra từ BRD_v1.md §9.1 "Thực thể chính" + §9.2 ràng buộc.
-- Nguồn: docs/Business_Requirements/BRD_v1.md (baseline v1.0).
-- CẢNH BÁO: đây KHÔNG phải schema vật lý đã chốt. Kiểu dữ liệu là placeholder,
-- vì tech stack/DB còn mở (OD-01) và BRD đặt "ERD vật lý" ra ngoài phạm vi (Sprint 0).
-- Mỗi bảng tenant-scoped có tenant_id theo BR-01. Bảng toàn nền tảng không có tenant_id.

CREATE TABLE "user" (
  id uuid PRIMARY KEY,
  email text,
  phone text,
  password_hash text,
  status text
);

CREATE TABLE platform_admin (
  user_id uuid PRIMARY KEY REFERENCES "user"(id),
  level text
);

CREATE TABLE owner_tenant (
  id uuid PRIMARY KEY,
  owner_user_id uuid REFERENCES "user"(id),
  name text,
  status text
);

CREATE TABLE staff_membership (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  user_id uuid REFERENCES "user"(id),
  status text
);

CREATE TABLE role (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  name text,
  is_system bool
);

CREATE TABLE permission (
  code text PRIMARY KEY,
  "group" text,
  is_sensitive bool
);

CREATE TABLE role_permission (
  role_id uuid REFERENCES role(id),
  permission_code text REFERENCES permission(code),
  PRIMARY KEY (role_id, permission_code)
);

CREATE TABLE role_assignment (
  id uuid PRIMARY KEY,
  membership_id uuid REFERENCES staff_membership(id),
  role_id uuid REFERENCES role(id),
  property_scope text
);

CREATE TABLE property (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  name text,
  address text,
  rules text
);

CREATE TABLE room (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  property_id uuid REFERENCES property(id),
  code text,
  area numeric,
  rent bigint,
  deposit bigint,
  status text
);

CREATE TABLE tariff (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  property_id uuid REFERENCES property(id),
  room_id uuid REFERENCES room(id),
  type text,
  method text,
  price bigint,
  effective_from date,
  effective_to date
);

CREATE TABLE listing (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  room_id uuid REFERENCES room(id),
  status text,
  current_revision_id uuid REFERENCES listing_revision(id)
);

CREATE TABLE listing_revision (
  id uuid PRIMARY KEY,
  listing_id uuid REFERENCES listing(id),
  version_no int,
  title text,
  description text,
  price bigint,
  amenities text,
  status text,
  feedback text
);

CREATE TABLE listing_photo (
  id uuid PRIMARY KEY,
  revision_id uuid REFERENCES listing_revision(id),
  object_key text,
  sort_order int,
  is_cover bool
);

CREATE TABLE viewing_request (
  id uuid PRIMARY KEY,
  listing_id uuid REFERENCES listing(id),
  seeker_name text,
  phone text,
  message text,
  preferred_at timestamptz,
  status text
);

CREATE TABLE lease (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  room_id uuid REFERENCES room(id),
  representative_user_id uuid REFERENCES "user"(id),
  start_date date,
  end_date date,
  rent bigint,
  deposit bigint,
  status text,
  version int
);

CREATE TABLE lease_version (
  id uuid PRIMARY KEY,
  lease_id uuid REFERENCES lease(id),
  version_no int,
  content_hash text,
  snapshot jsonb
);

CREATE TABLE lease_signature (
  id uuid PRIMARY KEY,
  lease_version_id uuid REFERENCES lease_version(id),
  user_id uuid REFERENCES "user"(id),
  role text,
  signed_at timestamptz,
  ip text,
  device text,
  hash text
);

CREATE TABLE occupant (
  id uuid PRIMARY KEY,
  lease_id uuid REFERENCES lease(id),
  full_name text,
  dob date,
  id_number text,
  phone text,
  role text
);

CREATE TABLE occupant_document (
  id uuid PRIMARY KEY,
  occupant_id uuid REFERENCES occupant(id),
  type text,
  object_key text,
  status text
);

CREATE TABLE condition_report (
  id uuid PRIMARY KEY,
  lease_id uuid REFERENCES lease(id),
  type text,
  status text,
  locked_at timestamptz
);

CREATE TABLE condition_area (
  id uuid PRIMARY KEY,
  report_id uuid REFERENCES condition_report(id),
  name text,
  note text,
  condition text
);

CREATE TABLE condition_photo (
  id uuid PRIMARY KEY,
  area_id uuid REFERENCES condition_area(id),
  object_key text,
  captured_at timestamptz,
  uploaded_by uuid REFERENCES "user"(id)
);

CREATE TABLE meter_reading (
  id uuid PRIMARY KEY,
  room_id uuid REFERENCES room(id),
  utility text,
  period text,
  previous int,
  current int,
  photo_key text,
  status text,
  confirmed_at timestamptz
);

CREATE TABLE invoice (
  id uuid PRIMARY KEY,
  lease_id uuid REFERENCES lease(id),
  replaces_invoice_id uuid REFERENCES invoice(id),
  period text,
  due_date date,
  total bigint,
  status text,
  issued_at timestamptz,
  void_reason text
);

CREATE TABLE invoice_line (
  id uuid PRIMARY KEY,
  invoice_id uuid REFERENCES invoice(id),
  type text,
  description text,
  quantity numeric,
  unit_price bigint,
  amount bigint
);

CREATE TABLE payment_record (
  id uuid PRIMARY KEY,
  invoice_id uuid REFERENCES invoice(id),
  amount bigint,
  paid_at timestamptz,
  proof_key text,
  reference text,
  status text,
  confirmed_by uuid REFERENCES "user"(id)
);

CREATE TABLE ticket (
  id uuid PRIMARY KEY,
  room_id uuid REFERENCES room(id),
  created_by uuid REFERENCES "user"(id),
  category text,
  title text,
  description text,
  priority text,
  status text
);

CREATE TABLE ticket_message (
  id uuid PRIMARY KEY,
  ticket_id uuid REFERENCES ticket(id),
  author_id uuid REFERENCES "user"(id),
  body text,
  is_internal bool
);

CREATE TABLE notification (
  id uuid PRIMARY KEY,
  recipient_id uuid REFERENCES "user"(id),
  type text,
  entity_type text,
  entity_id uuid,
  title text,
  body text,
  read_at timestamptz
);

CREATE TABLE device_token (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES "user"(id),
  platform text,
  token text
);

CREATE TABLE audit_event (
  id uuid PRIMARY KEY,
  actor_user_id uuid REFERENCES "user"(id),
  tenant_id uuid REFERENCES owner_tenant(id),
  action text,
  entity_type text,
  entity_id uuid,
  before jsonb,
  after jsonb,
  ip text,
  user_agent text,
  request_id text,
  reason text,
  occurred_at timestamptz
);

CREATE TABLE file_object (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES owner_tenant(id),
  object_key text,
  content_type text,
  size bigint,
  checksum text,
  owner_user_id uuid REFERENCES "user"(id)
);

CREATE TABLE idempotency_key (
  id uuid PRIMARY KEY,
  key text,
  user_id uuid REFERENCES "user"(id),
  endpoint text,
  response_hash text,
  expires_at timestamptz
);
