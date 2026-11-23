-- ERD logic (mức nghiệp vụ) — 36 thực thể chính theo BRD v1.8 §9.1.
-- Nguồn: docs/business-requirements/BRD.md (baseline v1.8, 2026-11-23).
-- Tech stack: PostgreSQL là write DB; MongoDB là read model rebuild được.
-- Web: Next.js + Tailwind CSS + GSAP; một web app responsive cho mọi actor.
-- Push: Web Push (FCM); DeviceToken lưu Web Push subscription.
-- BRD v1.6 bỏ mobile; mô hình dữ liệu không có entity mobile-specific.
-- CẢNH BÁO: đây KHÔNG phải schema vật lý đã chốt; kiểu dữ liệu là placeholder logic.
--
-- Các tính năng FR được lưu trong entity hiện hữu, không sinh thêm bảng:
--   User.notification_preferences
--   Notification.property_id / sent_by / recipient_count  (broadcast theo Property)
--   ConditionReport.parent_report_id + deposit refund fields (phụ lục & hoàn cọc)
--   Ticket.photo_keys (0–10 ảnh)
-- Các bảng hạ tầng như session, invitation token, support access, outbox, CAP projection
-- không phải thực thể nghiệp vụ chính nên không đưa vào ERD logic này.
-- Rate limit dùng Redis ephemeral (D-27..D-29) — policy versioned, không phải entity ERD.

CREATE TABLE "user" (
  "id" uuid PRIMARY KEY,
  "email" text,
  "phone" text,
  "password_hash" text,
  "display_name" text,
  "status" text,
  "created_at" timestamptz,
  "updated_at" timestamptz,
  "notification_preferences" jsonb
);
COMMENT ON TABLE "user" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "platform_admin" (
  "user_id" uuid PRIMARY KEY,
  "level" text,
  "created_at" timestamptz
);
COMMENT ON TABLE "platform_admin" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "owner_tenant" (
  "id" uuid PRIMARY KEY,
  "owner_user_id" uuid,
  "name" text,
  "status" text,
  "status_reason" text,
  "auto_approve" bool,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "owner_tenant" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "staff_membership" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "user_id" uuid,
  "status" text,
  "membership_version" int,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "staff_membership" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "role" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "name" text,
  "is_system" bool,
  "created_at" timestamptz
);
COMMENT ON TABLE "role" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "permission" (
  "code" text PRIMARY KEY,
  "group" text,
  "description" text,
  "is_sensitive" bool
);
COMMENT ON TABLE "permission" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "role_permission" (
  "tenant_id" uuid,
  "role_id" uuid,
  "permission_code" text,
  PRIMARY KEY ("role_id", "tenant_id", "permission_code")
);
COMMENT ON TABLE "role_permission" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "role_assignment" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "membership_id" uuid,
  "role_id" uuid,
  "property_scope" jsonb,
  "created_at" timestamptz
);
COMMENT ON TABLE "role_assignment" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "audit_event" (
  "id" uuid PRIMARY KEY,
  "occurred_at" timestamptz,
  "actor_user_id" uuid,
  "actor_role" text,
  "is_anonymous" bool,
  "tenant_id" uuid,
  "action" text,
  "entity_type" text,
  "entity_id" uuid,
  "lease_revision_id" uuid,
  "result" text,
  "before" jsonb,
  "after" jsonb,
  "ip" text,
  "user_agent" text,
  "request_id" text,
  "reason" text
);
COMMENT ON TABLE "audit_event" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "file_object" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "object_key" text,
  "content_type" text,
  "size_bytes" bigint,
  "checksum" text,
  "purpose" text,
  "status" text,
  "uploaded_by" uuid,
  "created_at" timestamptz
);
COMMENT ON TABLE "file_object" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "notification" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "recipient_id" uuid,
  "type" text,
  "entity_type" text,
  "entity_id" uuid,
  "title" text,
  "body" text,
  "announcement_id" uuid,
  "push_status" text,
  "push_attempts" int,
  "sent_at" timestamptz,
  "read_at" timestamptz,
  "created_at" timestamptz,
  "property_id" uuid,
  "sent_by" uuid,
  "recipient_count" int
);
COMMENT ON TABLE "notification" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "device_token" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid,
  "platform" text,
  "token" text,
  "last_seen_at" timestamptz,
  "revoked_at" timestamptz
);
COMMENT ON TABLE "device_token" IS 'Web Push subscription (FCM); token lưu endpoint + keys; platform = browser/OS.';
CREATE TABLE "idempotency_key" (
  "id" uuid PRIMARY KEY,
  "key" text,
  "user_id" uuid,
  "tenant_id" uuid,
  "endpoint" text,
  "request_hash" text,
  "response_hash" text,
  "status" text,
  "expires_at" timestamptz,
  "created_at" timestamptz
);
COMMENT ON TABLE "idempotency_key" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "property" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "name" text,
  "address" text,
  "province" text,
  "district" text,
  "ward" text,
  "amenities" jsonb,
  "rules" text,
  "notes" text,
  "status" text,
  "archived_at" timestamptz,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "property" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "room" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "property_id" uuid,
  "code" text,
  "area" numeric(8,2),
  "rent" bigint,
  "deposit" bigint,
  "amenities" jsonb,
  "status" text,
  "version" int,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "room" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "tariff" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "property_id" uuid,
  "room_id" uuid,
  "type" text,
  "method" text,
  "price" bigint,
  "effective_from" date,
  "effective_to" date,
  "created_by" uuid,
  "created_at" timestamptz
);
COMMENT ON TABLE "tariff" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "listing" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "room_id" uuid,
  "status" text,
  "current_revision_id" uuid,
  "closed_at" timestamptz,
  "close_reason" text,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "listing" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "listing_revision" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "listing_id" uuid,
  "version_no" int,
  "title" text,
  "description" text,
  "price" bigint,
  "amenities" jsonb,
  "available_from" date,
  "hide_exact_address" bool,
  "status" text,
  "feedback" text,
  "submitted_at" timestamptz,
  "reviewed_by" uuid,
  "reviewed_at" timestamptz,
  "created_at" timestamptz
);
COMMENT ON TABLE "listing_revision" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "listing_photo" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "revision_id" uuid,
  "object_key" text,
  "sort_order" int,
  "is_cover" bool,
  "created_at" timestamptz
);
COMMENT ON TABLE "listing_photo" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "viewing_request" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "listing_id" uuid,
  "seeker_name" text,
  "phone" text,
  "message" text,
  "preferred_at" timestamptz,
  "status" text,
  "owner_note" text,
  "contacted_at" timestamptz,
  "scheduled_at" timestamptz,
  "completed_at" timestamptz,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "viewing_request" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "lease_template" (
  "id" uuid PRIMARY KEY,
  "scope" text,
  "tenant_id" uuid,
  "code" text,
  "name" text,
  "version" int,
  "body" text,
  "status" text,
  "created_by" uuid,
  "created_at" timestamptz,
  "published_at" timestamptz,
  "archived_at" timestamptz
);
COMMENT ON TABLE "lease_template" IS 'BRD v1.8 §9.1; scope=system|tenant; version bất biến khi publish';
CREATE TABLE "lease" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "room_id" uuid,
  "representative_user_id" uuid,
  "template_id" uuid,
  "template_version" int,
  "current_revision_no" int,
  "start_date" date,
  "end_date" date,
  "rent" bigint,
  "deposit" bigint,
  "billing_cycle" text,
  "payment_due_day" int,
  "status" text,
  "version" int,
  "handover_at" timestamptz,
  "terminated_at" timestamptz,
  "termination_reason" text,
  "created_at" timestamptz,
  "updated_at" timestamptz
);
COMMENT ON TABLE "lease" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "lease_version" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "lease_id" uuid,
  "template_id" uuid,
  "template_version" int,
  "version_no" int,
  "change_type" text,
  "change_reason" text,
  "content_hash" text,
  "snapshot" jsonb,
  "pdf_object_key" text,
  "pdf_hash" text,
  "created_by" uuid,
  "created_at" timestamptz
);
COMMENT ON TABLE "lease_version" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "lease_revision" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "lease_id" uuid,
  "revision_no" int,
  "change_type" text,
  "before_hash" text,
  "after_hash" text,
  "snapshot" jsonb,
  "actor_user_id" uuid,
  "reason" text,
  "created_at" timestamptz
);
COMMENT ON TABLE "lease_revision" IS 'BRD v1.8 §9.1; append-only, unique (lease_id, revision_no)';
CREATE TABLE "lease_signature" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "lease_version_id" uuid,
  "user_id" uuid,
  "role" text,
  "signed_at" timestamptz,
  "ip" text,
  "device" text,
  "hash" text,
  "consent_version" text,
  "created_at" timestamptz
);
COMMENT ON TABLE "lease_signature" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "occupant" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "lease_id" uuid,
  "full_name" text,
  "dob" date,
  "id_number" text,
  "phone" text,
  "role" text,
  "guardian_note" text,
  "created_at" timestamptz
);
COMMENT ON TABLE "occupant" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "occupant_document" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "occupant_id" uuid,
  "lease_id" uuid,
  "side" text,
  "object_key" text,
  "status" text,
  "archived_at" timestamptz,
  "uploaded_by" uuid,
  "created_at" timestamptz
);
COMMENT ON TABLE "occupant_document" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "condition_report" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "lease_id" uuid,
  "type" text,
  "status" text,
  "sent_at" timestamptz,
  "renter_responded_at" timestamptz,
  "locked_at" timestamptz,
  "locked_by" uuid,
  "unconfirmed_checkout" bool,
  "unconfirmed_reason" text,
  "pdf_object_key" text,
  "created_by" uuid,
  "created_at" timestamptz,
  "updated_at" timestamptz,
  "parent_report_id" uuid,
  "deposit_amount" bigint,
  "deduction_amount" bigint,
  "refund_amount" bigint,
  "refund_method" text,
  "refund_note" text,
  "refund_recorded_by" uuid,
  "refund_recorded_at" timestamptz
);
COMMENT ON TABLE "condition_report" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "condition_area" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "report_id" uuid,
  "name" text,
  "note" text,
  "condition" text,
  "damage_note" text,
  "proposed_deduction" bigint,
  "sort_order" int
);
COMMENT ON TABLE "condition_area" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "condition_photo" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "area_id" uuid,
  "object_key" text,
  "captured_at" timestamptz,
  "uploaded_by" uuid,
  "uploaded_at" timestamptz,
  "sort_order" int
);
COMMENT ON TABLE "condition_photo" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "meter_reading" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "room_id" uuid,
  "lease_id" uuid,
  "utility" text,
  "period" text,
  "previous" int,
  "current" int,
  "photo_key" text,
  "meter_replaced" bool,
  "note" text,
  "status" text,
  "recorded_at" timestamptz,
  "confirmed_at" timestamptz,
  "disputed_reason" text,
  "created_by" uuid,
  "created_at" timestamptz
);
COMMENT ON TABLE "meter_reading" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "invoice" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "lease_id" uuid,
  "replaces_invoice_id" uuid,
  "period" text,
  "issue_date" date,
  "due_date" date,
  "total" bigint,
  "status" text,
  "unconfirmed_reading" bool,
  "unconfirmed_invoice" bool,
  "issued_at" timestamptz,
  "confirmed_at" timestamptz,
  "issued_by" uuid,
  "voided_at" timestamptz,
  "voided_by" uuid,
  "void_reason" text,
  "version" int,
  "created_at" timestamptz
);
COMMENT ON TABLE "invoice" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "invoice_line" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "invoice_id" uuid,
  "line_type" text,
  "description" text,
  "quantity" numeric(12,3),
  "unit_price" bigint,
  "amount" bigint,
  "source_tariff_id" uuid,
  "sort_order" int
);
COMMENT ON TABLE "invoice_line" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "payment_record" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "invoice_id" uuid,
  "amount" bigint,
  "paid_at" timestamptz,
  "proof_key" text,
  "reference" text,
  "status" text,
  "previous_invoice_status" text,
  "submitted_by" uuid,
  "confirmed_by" uuid,
  "confirmed_at" timestamptz,
  "rejection_reason" text,
  "created_at" timestamptz
);
COMMENT ON TABLE "payment_record" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "ticket" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "room_id" uuid,
  "lease_id" uuid,
  "created_by" uuid,
  "category" text,
  "title" text,
  "description" text,
  "priority" text,
  "status" text,
  "resolved_at" timestamptz,
  "closed_at" timestamptz,
  "reopen_deadline" timestamptz,
  "version" int,
  "created_at" timestamptz,
  "updated_at" timestamptz,
  "photo_keys" jsonb
);
COMMENT ON TABLE "ticket" IS 'Thực thể chính BRD v1.8 §9.1';
CREATE TABLE "ticket_message" (
  "id" uuid PRIMARY KEY,
  "tenant_id" uuid,
  "ticket_id" uuid,
  "author_id" uuid,
  "body" text,
  "is_internal" bool,
  "created_at" timestamptz
);
COMMENT ON TABLE "ticket_message" IS 'Thực thể chính BRD v1.8 §9.1';

-- ===== Khóa ngoại =====
ALTER TABLE "platform_admin" ADD CONSTRAINT "fk_platform_admin_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id");
ALTER TABLE "owner_tenant" ADD CONSTRAINT "fk_owner_tenant_owner_user_id" FOREIGN KEY ("owner_user_id") REFERENCES "user" ("id");
ALTER TABLE "staff_membership" ADD CONSTRAINT "fk_staff_membership_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "staff_membership" ADD CONSTRAINT "fk_staff_membership_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id");
ALTER TABLE "role" ADD CONSTRAINT "fk_role_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "role_permission" ADD CONSTRAINT "fk_role_permission_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "role_permission" ADD CONSTRAINT "fk_role_permission_role_id" FOREIGN KEY ("role_id") REFERENCES "role" ("id");
ALTER TABLE "role_permission" ADD CONSTRAINT "fk_role_permission_permission_code" FOREIGN KEY ("permission_code") REFERENCES "permission" ("code");
ALTER TABLE "role_assignment" ADD CONSTRAINT "fk_role_assignment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "role_assignment" ADD CONSTRAINT "fk_role_assignment_membership_id" FOREIGN KEY ("membership_id") REFERENCES "staff_membership" ("id");
ALTER TABLE "role_assignment" ADD CONSTRAINT "fk_role_assignment_role_id" FOREIGN KEY ("role_id") REFERENCES "role" ("id");
ALTER TABLE "audit_event" ADD CONSTRAINT "fk_audit_event_actor_user_id" FOREIGN KEY ("actor_user_id") REFERENCES "user" ("id");
ALTER TABLE "audit_event" ADD CONSTRAINT "fk_audit_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "audit_event" ADD CONSTRAINT "fk_audit_event_lease_revision_id" FOREIGN KEY ("lease_revision_id") REFERENCES "lease_revision" ("id");
ALTER TABLE "file_object" ADD CONSTRAINT "fk_file_object_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "file_object" ADD CONSTRAINT "fk_file_object_uploaded_by" FOREIGN KEY ("uploaded_by") REFERENCES "user" ("id");
ALTER TABLE "notification" ADD CONSTRAINT "fk_notification_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "notification" ADD CONSTRAINT "fk_notification_recipient_id" FOREIGN KEY ("recipient_id") REFERENCES "user" ("id");
ALTER TABLE "device_token" ADD CONSTRAINT "fk_device_token_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id");
ALTER TABLE "idempotency_key" ADD CONSTRAINT "fk_idempotency_key_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id");
ALTER TABLE "idempotency_key" ADD CONSTRAINT "fk_idempotency_key_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "property" ADD CONSTRAINT "fk_property_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "room" ADD CONSTRAINT "fk_room_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "room" ADD CONSTRAINT "fk_room_property_id" FOREIGN KEY ("property_id") REFERENCES "property" ("id");
ALTER TABLE "tariff" ADD CONSTRAINT "fk_tariff_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "tariff" ADD CONSTRAINT "fk_tariff_property_id" FOREIGN KEY ("property_id") REFERENCES "property" ("id");
ALTER TABLE "tariff" ADD CONSTRAINT "fk_tariff_room_id" FOREIGN KEY ("room_id") REFERENCES "room" ("id");
ALTER TABLE "tariff" ADD CONSTRAINT "fk_tariff_created_by" FOREIGN KEY ("created_by") REFERENCES "user" ("id");
ALTER TABLE "listing" ADD CONSTRAINT "fk_listing_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "listing" ADD CONSTRAINT "fk_listing_room_id" FOREIGN KEY ("room_id") REFERENCES "room" ("id");
ALTER TABLE "listing" ADD CONSTRAINT "fk_listing_current_revision_id" FOREIGN KEY ("current_revision_id") REFERENCES "listing_revision" ("id");
ALTER TABLE "listing_revision" ADD CONSTRAINT "fk_listing_revision_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "listing_revision" ADD CONSTRAINT "fk_listing_revision_listing_id" FOREIGN KEY ("listing_id") REFERENCES "listing" ("id");
ALTER TABLE "listing_revision" ADD CONSTRAINT "fk_listing_revision_reviewed_by" FOREIGN KEY ("reviewed_by") REFERENCES "user" ("id");
ALTER TABLE "listing_photo" ADD CONSTRAINT "fk_listing_photo_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "listing_photo" ADD CONSTRAINT "fk_listing_photo_revision_id" FOREIGN KEY ("revision_id") REFERENCES "listing_revision" ("id");
ALTER TABLE "viewing_request" ADD CONSTRAINT "fk_viewing_request_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "viewing_request" ADD CONSTRAINT "fk_viewing_request_listing_id" FOREIGN KEY ("listing_id") REFERENCES "listing" ("id");
ALTER TABLE "lease_template" ADD CONSTRAINT "fk_lease_template_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "lease_template" ADD CONSTRAINT "fk_lease_template_created_by" FOREIGN KEY ("created_by") REFERENCES "user" ("id");
ALTER TABLE "lease" ADD CONSTRAINT "fk_lease_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "lease" ADD CONSTRAINT "fk_lease_room_id" FOREIGN KEY ("room_id") REFERENCES "room" ("id");
ALTER TABLE "lease" ADD CONSTRAINT "fk_lease_representative_user_id" FOREIGN KEY ("representative_user_id") REFERENCES "user" ("id");
ALTER TABLE "lease" ADD CONSTRAINT "fk_lease_template_id" FOREIGN KEY ("template_id") REFERENCES "lease_template" ("id");
ALTER TABLE "lease_version" ADD CONSTRAINT "fk_lease_version_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "lease_version" ADD CONSTRAINT "fk_lease_version_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "lease_version" ADD CONSTRAINT "fk_lease_version_template_id" FOREIGN KEY ("template_id") REFERENCES "lease_template" ("id");
ALTER TABLE "lease_version" ADD CONSTRAINT "fk_lease_version_created_by" FOREIGN KEY ("created_by") REFERENCES "user" ("id");
ALTER TABLE "lease_revision" ADD CONSTRAINT "fk_lease_revision_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "lease_revision" ADD CONSTRAINT "fk_lease_revision_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "lease_revision" ADD CONSTRAINT "fk_lease_revision_actor_user_id" FOREIGN KEY ("actor_user_id") REFERENCES "user" ("id");
ALTER TABLE "lease_signature" ADD CONSTRAINT "fk_lease_signature_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "lease_signature" ADD CONSTRAINT "fk_lease_signature_lease_version_id" FOREIGN KEY ("lease_version_id") REFERENCES "lease_version" ("id");
ALTER TABLE "lease_signature" ADD CONSTRAINT "fk_lease_signature_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id");
ALTER TABLE "occupant" ADD CONSTRAINT "fk_occupant_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "occupant" ADD CONSTRAINT "fk_occupant_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "occupant_document" ADD CONSTRAINT "fk_occupant_document_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "occupant_document" ADD CONSTRAINT "fk_occupant_document_occupant_id" FOREIGN KEY ("occupant_id") REFERENCES "occupant" ("id");
ALTER TABLE "occupant_document" ADD CONSTRAINT "fk_occupant_document_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "occupant_document" ADD CONSTRAINT "fk_occupant_document_uploaded_by" FOREIGN KEY ("uploaded_by") REFERENCES "user" ("id");
ALTER TABLE "condition_report" ADD CONSTRAINT "fk_condition_report_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "condition_report" ADD CONSTRAINT "fk_condition_report_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "condition_report" ADD CONSTRAINT "fk_condition_report_locked_by" FOREIGN KEY ("locked_by") REFERENCES "user" ("id");
ALTER TABLE "condition_report" ADD CONSTRAINT "fk_condition_report_created_by" FOREIGN KEY ("created_by") REFERENCES "user" ("id");
ALTER TABLE "condition_area" ADD CONSTRAINT "fk_condition_area_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "condition_area" ADD CONSTRAINT "fk_condition_area_report_id" FOREIGN KEY ("report_id") REFERENCES "condition_report" ("id");
ALTER TABLE "condition_photo" ADD CONSTRAINT "fk_condition_photo_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "condition_photo" ADD CONSTRAINT "fk_condition_photo_area_id" FOREIGN KEY ("area_id") REFERENCES "condition_area" ("id");
ALTER TABLE "condition_photo" ADD CONSTRAINT "fk_condition_photo_uploaded_by" FOREIGN KEY ("uploaded_by") REFERENCES "user" ("id");
ALTER TABLE "meter_reading" ADD CONSTRAINT "fk_meter_reading_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "meter_reading" ADD CONSTRAINT "fk_meter_reading_room_id" FOREIGN KEY ("room_id") REFERENCES "room" ("id");
ALTER TABLE "meter_reading" ADD CONSTRAINT "fk_meter_reading_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "meter_reading" ADD CONSTRAINT "fk_meter_reading_created_by" FOREIGN KEY ("created_by") REFERENCES "user" ("id");
ALTER TABLE "invoice" ADD CONSTRAINT "fk_invoice_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "invoice" ADD CONSTRAINT "fk_invoice_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "invoice" ADD CONSTRAINT "fk_invoice_replaces_invoice_id" FOREIGN KEY ("replaces_invoice_id") REFERENCES "invoice" ("id");
ALTER TABLE "invoice" ADD CONSTRAINT "fk_invoice_issued_by" FOREIGN KEY ("issued_by") REFERENCES "user" ("id");
ALTER TABLE "invoice" ADD CONSTRAINT "fk_invoice_voided_by" FOREIGN KEY ("voided_by") REFERENCES "user" ("id");
ALTER TABLE "invoice_line" ADD CONSTRAINT "fk_invoice_line_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "invoice_line" ADD CONSTRAINT "fk_invoice_line_invoice_id" FOREIGN KEY ("invoice_id") REFERENCES "invoice" ("id");
ALTER TABLE "invoice_line" ADD CONSTRAINT "fk_invoice_line_source_tariff_id" FOREIGN KEY ("source_tariff_id") REFERENCES "tariff" ("id");
ALTER TABLE "payment_record" ADD CONSTRAINT "fk_payment_record_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "payment_record" ADD CONSTRAINT "fk_payment_record_invoice_id" FOREIGN KEY ("invoice_id") REFERENCES "invoice" ("id");
ALTER TABLE "payment_record" ADD CONSTRAINT "fk_payment_record_submitted_by" FOREIGN KEY ("submitted_by") REFERENCES "user" ("id");
ALTER TABLE "payment_record" ADD CONSTRAINT "fk_payment_record_confirmed_by" FOREIGN KEY ("confirmed_by") REFERENCES "user" ("id");
ALTER TABLE "ticket" ADD CONSTRAINT "fk_ticket_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "ticket" ADD CONSTRAINT "fk_ticket_room_id" FOREIGN KEY ("room_id") REFERENCES "room" ("id");
ALTER TABLE "ticket" ADD CONSTRAINT "fk_ticket_lease_id" FOREIGN KEY ("lease_id") REFERENCES "lease" ("id");
ALTER TABLE "ticket" ADD CONSTRAINT "fk_ticket_created_by" FOREIGN KEY ("created_by") REFERENCES "user" ("id");
ALTER TABLE "ticket_message" ADD CONSTRAINT "fk_ticket_message_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "owner_tenant" ("id");
ALTER TABLE "ticket_message" ADD CONSTRAINT "fk_ticket_message_ticket_id" FOREIGN KEY ("ticket_id") REFERENCES "ticket" ("id");
ALTER TABLE "ticket_message" ADD CONSTRAINT "fk_ticket_message_author_id" FOREIGN KEY ("author_id") REFERENCES "user" ("id");
ALTER TABLE "notification" ADD CONSTRAINT "fk_notification_property_id" FOREIGN KEY ("property_id") REFERENCES "property" ("id");
ALTER TABLE "notification" ADD CONSTRAINT "fk_notification_sent_by" FOREIGN KEY ("sent_by") REFERENCES "user" ("id");
ALTER TABLE "condition_report" ADD CONSTRAINT "fk_condition_report_parent_report_id" FOREIGN KEY ("parent_report_id") REFERENCES "condition_report" ("id");
ALTER TABLE "condition_report" ADD CONSTRAINT "fk_condition_report_refund_recorded_by" FOREIGN KEY ("refund_recorded_by") REFERENCES "user" ("id");

-- ===== Unique / index =====
CREATE UNIQUE INDEX ux_user_email ON "user" (lower(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX ux_user_phone ON "user" (phone) WHERE phone IS NOT NULL;
CREATE UNIQUE INDEX ux_owner_tenant_owner ON owner_tenant (owner_user_id);
CREATE UNIQUE INDEX ux_staff_active_user ON staff_membership (user_id) WHERE status = 'Active';
CREATE UNIQUE INDEX ux_role_tenant_name ON role (tenant_id, name);
CREATE UNIQUE INDEX ux_role_assignment ON role_assignment (membership_id, role_id);
CREATE INDEX ix_staff_membership_tenant ON staff_membership (tenant_id, status);
CREATE INDEX ix_audit_tenant_time ON audit_event (tenant_id, occurred_at DESC);
CREATE INDEX ix_audit_entity ON audit_event (entity_type, entity_id);
CREATE INDEX ix_audit_actor ON audit_event (actor_user_id, occurred_at DESC);
CREATE INDEX ix_file_tenant ON file_object (tenant_id, created_at DESC);
CREATE INDEX ix_notification_recipient ON notification (recipient_id, read_at, created_at DESC);
CREATE INDEX ix_notification_tenant ON notification (tenant_id, type, created_at DESC);
CREATE INDEX ix_notification_property ON notification (tenant_id, property_id, created_at DESC);
CREATE UNIQUE INDEX ux_device_token ON device_token (token);
CREATE UNIQUE INDEX ux_idempotency_user_key ON idempotency_key (user_id, key);
CREATE INDEX ix_property_tenant ON property (tenant_id, status);
CREATE UNIQUE INDEX ux_room_code ON room (tenant_id, property_id, code);
CREATE INDEX ix_tariff_lookup ON tariff (tenant_id, type, effective_from);
CREATE UNIQUE INDEX ux_listing_open_room ON listing (room_id) WHERE status <> 'Closed';
CREATE UNIQUE INDEX ux_listing_revision_version ON listing_revision (listing_id, version_no);
CREATE UNIQUE INDEX ux_listing_revision_pending ON listing_revision (listing_id) WHERE status IN ('Draft', 'PendingReview');
CREATE UNIQUE INDEX ux_listing_photo_order ON listing_photo (revision_id, sort_order);
CREATE UNIQUE INDEX ux_listing_photo_cover ON listing_photo (revision_id) WHERE is_cover;
CREATE INDEX ix_viewing_request_listing ON viewing_request (listing_id, status, created_at DESC);
CREATE UNIQUE INDEX ux_lease_active_room ON lease (room_id) WHERE status = 'Active';
CREATE INDEX ix_lease_tenant_status ON lease (tenant_id, status, end_date);
CREATE INDEX ix_lease_representative ON lease (representative_user_id, status);
CREATE UNIQUE INDEX ux_lease_template_version ON lease_template
  (scope, COALESCE(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid), code, version);
CREATE UNIQUE INDEX ux_lease_template_active ON lease_template
  (scope, COALESCE(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid), code)
  WHERE status IN ('Draft', 'Published');
CREATE UNIQUE INDEX ux_lease_revision_no ON lease_revision (lease_id, revision_no);
CREATE INDEX ix_lease_revision_lease ON lease_revision (lease_id, created_at DESC);
-- Append-only: thêm trigger DB chặn UPDATE/DELETE trên lease_revision (BR-53).
CREATE UNIQUE INDEX ux_lease_version ON lease_version (lease_id, version_no);
CREATE UNIQUE INDEX ux_lease_signature ON lease_signature (lease_version_id, user_id);
CREATE INDEX ix_occupant_lease ON occupant (lease_id);
CREATE UNIQUE INDEX ux_occupant_document_side ON occupant_document (occupant_id, side);
CREATE INDEX ix_occupant_document_archive ON occupant_document (lease_id, status);
CREATE INDEX ix_condition_report_lease ON condition_report (lease_id, type, created_at DESC);
CREATE INDEX ix_condition_parent ON condition_report (parent_report_id);
CREATE UNIQUE INDEX ux_condition_area_name ON condition_area (report_id, name);
CREATE INDEX ix_condition_photo_area ON condition_photo (area_id, sort_order);
CREATE UNIQUE INDEX ux_meter_reading_period ON meter_reading (room_id, utility, period);
CREATE INDEX ix_meter_reading_lease ON meter_reading (lease_id, period);
CREATE UNIQUE INDEX ux_invoice_current_period ON invoice (lease_id, period) WHERE status <> 'Void';
CREATE INDEX ix_invoice_due ON invoice (tenant_id, status, due_date);
CREATE INDEX ix_invoice_line ON invoice_line (invoice_id, sort_order);
CREATE INDEX ix_payment_record_invoice ON payment_record (invoice_id, status, created_at DESC);
CREATE INDEX ix_ticket_tenant_status ON ticket (tenant_id, status, created_at DESC);
CREATE INDEX ix_ticket_room ON ticket (room_id, status, created_at DESC);
CREATE INDEX ix_ticket_message ON ticket_message (ticket_id, created_at);

-- ===== Ghi chú =====
-- 1. Tiền là bigint (đồng), không dùng double/float (BR-25).
-- 2. Hóa đơn đã phát hành là bất biến; điều chỉnh bằng void + hóa đơn thay thế (BR-22).
-- 3. Biên bản Locked là bất biến; thay đổi qua condition_report.parent_report_id (BR-29).
-- 4. MongoDB read model không có DDL ở đây; mọi document tenant-scoped có tenantId và rebuild từ PostgreSQL.
