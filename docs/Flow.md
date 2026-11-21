# Flow làm việc nhóm — BRD + OpenSpec

| Thuộc tính | Giá trị |
|---|---|
| Phiên bản | 1.0 |
| Ngày | 2026-11-21 |
| Áp dụng cho | Dự án `kasio` và các dự án dùng chung quy trình |
| Tài liệu liên quan | `docs/Business_Requirements/BRD_v1.md` |
| Mục đích | Thống nhất cách chuyển yêu cầu nghiệp vụ thành change, code, review và archive |

> **BRD là nguồn sự thật về sản phẩm. OpenSpec là nguồn sự thật về change đang làm và spec đã build.**
> Tài liệu này không thay thế BRD; nó quy định cách team làm việc với BRD.

---

## 1. Nguyên tắc

1. **Không code trước khi có change plan được duyệt.** Ngoại lệ duy nhất là hotfix P0 có Tech Lead duyệt, và phải backfill change trong 24 giờ.
2. **Một change = một capability quan sát được.** Không tạo change `add-whole-saas`.
3. **`tasks.md` là nguồn tiến độ duy nhất.** Không có checklist ẩn trong chat/board.
4. **Main spec là hệ thống đã build.** Sau archive, `openspec/specs/` phải phản ánh đúng code.
5. **Tenant isolation, authorization và audit là gate cứng.** Thiếu test tương ứng thì không merge.
6. **Không mở scope trong lúc apply.** Ý mới → tạo change mới, không nhét vào change hiện tại.
7. **Plan là markdown.** Sửa tay được; nhưng nếu sửa làm lệch các artifact khác, dùng `openspec-update-change`.

---

## 2. Cài đặt và cấu trúc

### 2.1 Mỗi máy thành viên

Cài CLI một lần:

```bash
curl -fsSL https://openspec.dev/cli/install.sh | sh
openspec --version
```

Cài skill global cho agent đang dùng. Ví dụ với omp:

```bash
cd /path/to/kasio
openspec init --tools oh-my-pi --scope global --language vi
```

Với agent khác, thay `oh-my-pi` bằng ID tương ứng (`opencode`, `claude`, `cursor`, ...):

```bash
openspec init --tools <agent-id> --scope global --language vi
```

Kiểm tra:

```bash
openspec list
omp skill list --json | jq -r '.skills[] | select(.name|startswith("openspec")) | .name'
```

Skill nằm ở `~/.agents/skills/`, dùng cho **mọi project** trên máy. Không commit thư mục skill global vào repo.

Cập nhật skill định kỳ:

```bash
openspec update
```

### 2.2 Mỗi repo mới

Chỉ cần tạo cấu trúc OpenSpec cho repo, không cài lại skill:

```bash
cd /path/to/new-repo
openspec init --tools none --language vi
```

CI tối thiểu nên chạy:

```bash
openspec validate --all
```

Kết quả tối thiểu:

```text
repo/
├── docs/
│   ├── Flow.md
│   └── Business_Requirements/
│       └── BRD_v1.md
├── openspec/
│   ├── config.yaml
│   ├── specs/                  # hệ thống đã build
│   └── changes/
│       ├── <change-name>/      # change đang làm
│       └── archive/            # lịch sử
└── src/
```

### 2.3 Cấu hình project

`openspec/config.yaml` nên ghi rõ context để mọi agent đọc cùng một luật:

```yaml
schema: spec-driven

context: |
  Language: vi
  All artifacts must be written in vi.
  Keep OpenSpec structural headings and SHALL/MUST keywords in English.

  Source of truth: docs/Business_Requirements/BRD_v1.md
  Read BRD_v1 before proposing a change.

  Non-negotiable:
  - Every tenant-scoped endpoint has a cross-tenant negative test.
  - Sensitive actions write an audit event.
  - No online payment, billing, group chat, offline mode, or auto image comparison.
  - One change = one observable capability.
```

Không đưa secret, token hay thông tin khách hàng vào `config.yaml`.

---

## 3. Sáu skill và thứ tự dùng

### 3.1 Vai trò từng skill

| Thứ tự | Skill | Làm gì | Sửa code? | Bắt buộc? |
|---|---|---|---|---|
| 0 | `openspec-explore` | Suy nghĩ, so sánh phương án, làm rõ yêu cầu | Không | Không |
| 1 | `openspec-propose` | Tạo change + `proposal.md`, `specs/`, `design.md`, `tasks.md` | Không | Có |
| 2 | `openspec-update-change` | Sửa plan cho khớp nhau | Không | Khi cần |
| 3 | `openspec-apply-change` | Implement từng task, tick `tasks.md` | Có | Có |
| 4 | `openspec-sync-specs` | Merge delta spec vào main spec, không archive | Không | Khi cần |
| 5 | `openspec-archive-change` | Đóng change, archive, merge spec | Không | Có |

**Không gọi cả 6 skill tuần tự.** Happy path chỉ có:

```text
explore? → propose → review → apply → archive
```

`update-change` và `sync-specs` là nhánh xử lý, không phải bước bắt buộc.

### 3.2 Happy path

```mermaid
flowchart LR
  B[BRD_v1.md] --> Q{Đủ rõ để làm?}
  Q -- Chưa --> E[openspec-explore]
  E --> P[openspec-propose]
  Q -- Rồi --> P
  P --> R[Review proposal / specs / tasks]
  R -- Cần sửa --> U[openspec-update-change]
  U --> R
  R -- Chốt --> A[openspec-apply-change]
  A -- Plan sai --> U
  A --> D{Tasks xong?}
  D -- Chưa --> A
  D -- Rồi --> S[openspec-sync-specs optional]
  S --> AR[openspec-archive-change]
  D -- Rồi --> AR
  AR --> M[openspec/specs = hệ thống đã build]
```

### 3.3 Cách gọi trong omp

Trong omp, gõ `/skill:` rồi chọn skill, hoặc dùng trực tiếp:

```text
/skill:openspec-explore "..."
/skill:openspec-propose add-tenant-auth-foundation
/skill:openspec-update-change add-tenant-auth-foundation
/skill:openspec-apply-change add-tenant-auth-foundation
/skill:openspec-sync-specs add-tenant-auth-foundation
/skill:openspec-archive-change add-tenant-auth-foundation
```

Agent khác có thể dùng `/openspec-propose`, hoặc mô tả bằng lời:

```text
Dùng openspec-propose để tạo change add-tenant-auth-foundation.
```

---

## 4. Gate và trạng thái

| Trạng thái | Artifact | Điều kiện vào | Người duyệt |
|---|---|---|---|
| `Backlog` | Chưa có change | Yêu cầu đã có trong BRD/OD | Product Owner |
| `Proposed` | `openspec/changes/<name>/` | Đã chạy propose, đủ artifact | Dev |
| `Plan Approved` | `proposal.md`, `specs/`, `tasks.md` | Review plan pass, `openspec validate` pass | Product Owner + Tech Lead |
| `In Progress` | `tasks.md` đang tick | Plan Approved; task đầu tiên bắt đầu | Dev |
| `In Review` | PR + code + test | Tasks chính xong, test pass | Reviewer |
| `Done` | Change đã archive | PR merged; main spec đã sync | Tech Lead |

### Gate bắt buộc

- **G1 — Plan gate:** proposal nêu rõ why/scope/out-of-scope; spec testable; tasks ≤ 1 ngày/task.
- **G2 — Code gate:** test pass; cross-tenant test cho endpoint tenant-scoped; audit cho thao tác nhạy cảm; không có scope mới.
- **G3 — Archive gate:** tất cả task `[x]`; PR đã merge; `openspec validate --all` pass; main spec đã sync.

---

## 5. Quy trình 7 bước

### Bước 1 — Chọn change

Nguồn:

- BRD v1, mục 12.2 (epic) và 12.3 (sprint).
- `OD-*` đã chốt.
- Bug/incident có trong backlog.

Mỗi change phải trả lời được:

- Capability nào thay đổi?
- Ai dùng?
- Thành công đo bằng gì?
- Không làm gì?

Nếu chưa trả lời được, quay lại `explore`.

### Bước 2 — Explore (optional)

Dùng khi:

- Chưa chọn tech stack/kiến trúc.
- Yêu cầu mâu thuẫn.
- Cần so sánh 2–3 phương án.
- Chưa biết chia change như thế nào.

Ví dụ:

```text
/skill:openspec-explore "So sánh .NET, NestJS và Go cho SaaS multi-tenant, một người làm, cần auth, RBAC, audit, upload ảnh."
```

Kết quả mong đợi: quyết định + lý do + rủi ro. Không code.

### Bước 3 — Propose

```text
/skill:openspec-propose add-tenant-auth-foundation
```

Đầu ra:

```text
openspec/changes/add-tenant-auth-foundation/
├── proposal.md
├── specs/
│   └── tenant-auth/spec.md
├── design.md
└── tasks.md
```

Quy tắc:

- `proposal.md`: why, what, out-of-scope, impact.
- `specs/`: delta requirement, có scenario kiểm thử được; dùng `SHALL`/`MUST` bằng tiếng Anh theo cấu trúc OpenSpec.
- `design.md`: chỉ khi cần quyết định kỹ thuật; không nhồi code.
- `tasks.md`: task nhỏ, có thứ tự dependency, mỗi task ≤ 1 ngày.

### Bước 4 — Review plan

Review theo thứ tự:

1. `proposal.md` — đúng vấn đề, đúng scope?
2. `specs/` — nếu accept các requirement này là “done”, có thật sự done?
3. `tasks.md` — cover hết spec, không thừa?
4. `design.md` — quyết định kỹ thuật có rủi ro?

Thời hạn review: **1 ngày làm việc**. Quá hạn, người propose được ping lại.

Với change chạm auth/tenant/data model/CCCD, mở draft PR chứa `proposal.md` + `specs/` + `tasks.md` trước khi apply để review có chỗ bám và lưu lịch sử quyết định.

Nếu cần sửa:

```text
/skill:openspec-update-change add-tenant-auth-foundation
```

Hoặc sửa trực tiếp file markdown. Nếu thay đổi **mục tiêu** chứ không phải refine, tạo change mới.

### Bước 5 — Apply

Chỉ bắt đầu khi plan đã `Plan Approved`.

```text
/skill:openspec-apply-change add-tenant-auth-foundation
```

Quy tắc:

- Làm theo đúng thứ tự task.
- Mỗi task xong: tick `[x]`, chạy test liên quan.
- Gặp plan sai: dừng, dùng `update-change`, rồi apply tiếp.
- Gặp blocker: ghi rõ vào task/PR, không code tắt.
- Không thêm feature ngoài `specs/`.

### Bước 6 — Code review

PR phải có:

- Link tới change.
- `tasks.md` đã tick các task đã xong.
- Test pass.
- Test cross-tenant cho endpoint tenant-scoped.
- Audit event cho thao tác nhạy cảm.
- Không có file/thay đổi ngoài scope.
- Screenshot/video nếu là UI.

Reviewer dùng checklist ở mục 12.

### Bước 7 — Archive

Sau khi PR merge:

```text
/skill:openspec-archive-change add-tenant-auth-foundation
```

Archive sẽ:

- Kiểm tra task hoàn tất.
- Sync delta spec vào `openspec/specs/`.
- Chuyển change vào `openspec/changes/archive/YYYY-MM-DD-<name>/`.

Nếu chỉ muốn cập nhật main spec trước, chưa archive:

```text
/skill:openspec-sync-specs add-tenant-auth-foundation
```

---

## 6. Ví dụ đầy đủ: `add-tenant-auth-foundation`

Đây là change đầu tiên sau khi chốt tech stack.

### 6.1 Lệnh

```text
/skill:openspec-propose add-tenant-auth-foundation
```

### 6.2 `proposal.md` — ví dụ rút gọn

```markdown
# add-tenant-auth-foundation

## Why

BRD_v1 §4.1 và §6.1 yêu cầu Owner tự đăng ký, tenant tự tạo, Staff chỉ thuộc một Owner,
RBAC có phạm vi Property và audit cho thao tác nhạy cảm. Đây là nền tảng cho mọi module sau.

## What Changes

- Thêm User toàn nền tảng, đăng nhập bằng email/số điện thoại + mật khẩu.
- Owner đăng ký tự tạo Tenant và membership `owner`; tài khoản `Active` ngay.
- Staff được mời, gán role + Property scope; một Staff chỉ thuộc một Owner.
- Thêm permission catalog, role mặc định và kiểm tra quyền phía server.
- Thêm audit event cho đăng nhập, đổi quyền, mời/xóa Staff.
- Thêm test cách ly tenant cho mọi endpoint tenant-scoped.

## Out of Scope

- Property/Room/Listing.
- Billing/phí nền tảng.
- Thanh toán online.
- Chat nhóm.

## Impact

- Database: User, Tenant, Membership, Role, Permission, AuditEvent.
- API: auth, staff, role.
- Mobile: login, chọn vai trò, màn hình Staff.
```

### 6.3 `specs/tenant-auth/spec.md` — ví dụ delta spec

```markdown
## ADDED Requirements

### Requirement: Tenant isolation

The system SHALL derive `TenantId` from the authenticated membership and SHALL NOT accept
`tenantId` from the request body or query string.

#### Scenario: Cross-tenant read is denied

- **WHEN** Owner A requests a Property owned by Owner B
- **THEN** the API responds with 404
- **AND** an audit event records the denied access

### Requirement: Staff belongs to one Owner

The system SHALL allow a user to be an active Staff member of at most one Owner.

#### Scenario: Invite a Staff who already belongs to another Owner

- **WHEN** Owner B invites a user who is active Staff of Owner A
- **THEN** the invitation is rejected with a clear error
- **AND** no membership is created

### Requirement: Sensitive actions are audited

The system SHALL write an append-only audit event when a role or permission changes.

#### Scenario: Owner grants CCCD view permission

- **WHEN** Owner grants `document.cccd.view` to a Staff
- **THEN** an audit event records actor, tenant, target user, permission, timestamp, and request id
```

### 6.4 `tasks.md` — ví dụ

```markdown
## 1. Data model

- [ ] 1.1 Tạo migration User, Tenant, Membership, Role, Permission, AuditEvent
- [ ] 1.2 Thêm unique index cho email/phone và Staff active membership
- [ ] 1.3 Seed permission catalog và role mặc định

## 2. Auth

- [ ] 2.1 API đăng ký Owner + tạo Tenant
- [ ] 2.2 API đăng nhập, refresh, logout
- [ ] 2.3 Middleware resolve tenant từ membership

## 3. RBAC

- [ ] 3.1 Permission guard theo role + Property scope
- [ ] 3.2 API mời/xóa Staff
- [ ] 3.3 API gán role/permission

## 4. Audit

- [ ] 4.1 Ghi audit cho đăng nhập thất bại, đổi quyền, mời/xóa Staff
- [ ] 4.2 Màn hình audit cơ bản cho Owner

## 5. Test

- [ ] 5.1 Test cross-tenant cho từng endpoint tenant-scoped
- [ ] 5.2 Test Staff không thấy dữ liệu Property ngoài scope
- [ ] 5.3 Test thu hồi role có hiệu lực ngay
```

### 6.5 Review plan — ví dụ comment

Reviewer có thể chặn:

```text
- Spec thiếu scenario Staff bị thu hồi role nhưng token cũ vẫn dùng.
- Task 3.2 đang gộp invite + accept + remove; tách thành 3 task ≤ 1 ngày.
- Thiếu test cross-tenant cho endpoint danh sách Staff.
```

Dev sửa:

```text
/skill:openspec-update-change add-tenant-auth-foundation
```

Sau đó review lại. Chỉ khi pass mới:

```text
/skill:openspec-apply-change add-tenant-auth-foundation
```

### 6.6 Sau khi merge

```text
/skill:openspec-archive-change add-tenant-auth-foundation
```

Kết quả:

```text
openspec/specs/tenant-auth/spec.md                  # main spec
openspec/changes/archive/2026-11-21-add-tenant-auth-foundation/
```

---

## 7. Các nhánh xử lý

### 7.1 Plan sai giữa lúc apply

```text
apply → update-change → review nhanh → apply
```

Không tự ý sửa code khác spec. Nếu intent đổi hoàn toàn, tạo change mới.

### 7.2 Bug fix

Tạo change nhỏ:

```text
fix-listing-revision-visibility
```

- `proposal.md`: bug, impact, root cause.
- `specs/`: `MODIFIED Requirement` cho hành vi đúng.
- `tasks.md`: reproduce → fix → regression test → verify.

Không dùng change `add-*` để sửa bug.

### 7.3 Scope tăng

Tạo change mới. Không mở rộng change hiện tại, trừ khi scope mới là điều kiện bắt buộc để change hiện tại chạy đúng; khi đó phải update `proposal.md` và được Product Owner duyệt lại.

### 7.4 Hotfix P0

Ngoại lệ có kiểm soát:

1. Tech Lead duyệt hotfix.
2. Sửa tối thiểu + test regression.
3. Merge.
4. Tạo/backfill change `fix-*` trong 24 giờ, ghi rõ “hotfix backfill”.
5. Postmortem nếu lỗi ảnh hưởng người dùng.

Không dùng hotfix để trốn plan cho feature.

### 7.5 Hai change cùng đụng một spec

- Không chạy `sync-specs`/`archive` song song trên cùng capability.
- Merge change cũ trước; change sau rebase và cập nhật delta spec.
- Nếu conflict về requirement, chốt lại với Product Owner trước khi apply.

---

## 8. Quy ước đặt tên và Git

### 8.1 Change name

Kebab-case, verb-first:

```text
add-tenant-auth-foundation
add-property-room-crud
add-listing-moderation
update-lease-signing
fix-listing-revision-visibility
remove-legacy-import
```

Không đặt:

```text
sprint-1
backend
fix-bug
new-feature
```

### 8.2 Branch

```text
change/<change-name>
```

Ví dụ:

```text
change/add-tenant-auth-foundation
```

### 8.3 Commit

```text
feat(tenant-auth): add owner registration and tenant bootstrap
test(tenant-auth): cover cross-tenant staff access
fix(listing): keep published snapshot while revision is pending
```

### 8.4 PR

Title:

```text
[add-tenant-auth-foundation] Owner registration, tenant, RBAC, audit
```

PR description:

```markdown
## Change
openspec/changes/add-tenant-auth-foundation

## What
- Owner registration + tenant bootstrap
- Staff invite + RBAC
- Audit events

## Verification
- [ ] Unit tests
- [ ] Integration tests
- [ ] Cross-tenant tests
- [ ] Manual demo

## Out of scope
- Property/Room/Listing
```

---

## 9. Definition of Ready / Done

### 9.1 Definition of Ready (change)

- [ ] Có `proposal.md` với why/scope/out-of-scope.
- [ ] Có `specs/` với requirement testable.
- [ ] Có `tasks.md`, mỗi task ≤ 1 ngày.
- [ ] `OD-*` liên quan đã chốt hoặc có default được ghi rõ.
- [ ] Không có dependency chưa xong (hoặc đã ghi rõ thứ tự).
- [ ] `openspec validate <change>` pass.

### 9.2 Definition of Done (change)

- [ ] Tất cả task `[x]`.
- [ ] AC trong BRD mục 13 pass.
- [ ] Unit + integration test pass.
- [ ] Cross-tenant test cho mọi endpoint tenant-scoped.
- [ ] Audit event cho thao tác nhạy cảm.
- [ ] Migration chạy được trên DB sạch và DB có dữ liệu cũ.
- [ ] UI có loading/empty/error/retry.
- [ ] `openspec validate --all` pass.
- [ ] PR được review và merge.
- [ ] Demo trên staging.
- [ ] Change đã archive; main spec đã sync.

---

## 10. Nhịp sprint

| Thời điểm | Việc làm | Output |
|---|---|---|
| Đầu sprint | Chọn 1–2 change từ BRD/epic; review `OD-*` | Danh sách change + owner |
| Đầu sprint | Propose/review plan | Plan Approved |
| Trong sprint | Apply theo `tasks.md`; WIP = 1 | Task tick + PR |
| Giữa sprint | Kiểm tra scope; ý mới → backlog | Không đổi scope |
| Cuối sprint | Demo E2E; review/merge; archive | Change Done |
| Retro | Cập nhật Flow/BRD/OD; ghi blocker | Action item |

Quy tắc:

- Mỗi người tối đa **1 change đang apply**.
- Mỗi sprint tối đa **2 change đang mở** cho team nhỏ.
- Change không xong trong sprint: không cắt test; chuyển phần còn lại sang sprint sau hoặc tách change.
- Board chỉ track trạng thái/gate; tiến độ chi tiết nằm trong `tasks.md`.

---

## 11. Vai trò

| Vai trò | Trách nhiệm | Có thể kiêm nhiệm? |
|---|---|---|
| Product Owner | Ưu tiên, chốt scope/OD, duyệt `proposal.md`/`specs/` | Có |
| Tech Lead | Chốt `design.md`, review plan kỹ thuật, duyệt hotfix | Có |
| Dev | Propose, apply, test, PR | Không tự duyệt plan của mình nếu change chạm auth/tenant/data |
| Reviewer | Review code + test + audit + cross-tenant | Có thể là Tech Lead |
| QA | Kiểm AC, exploratory, regression | Có thể là Dev khác |

Với team 1–2 người:

- PO + Tech Lead có thể cùng một người.
- Change chạm auth/tenant/CCCD/payment **phải có ít nhất một người khác review**.
- Không ai tự merge change security-critical mà không có review.

---

## 12. Checklist review

### 12.1 Plan

- [ ] `proposal.md` nêu đúng vấn đề, scope, out-of-scope.
- [ ] `specs/` có scenario kiểm thử được, không mơ hồ.
- [ ] Có scenario cross-tenant.
- [ ] Có scenario permission bị từ chối.
- [ ] Có scenario audit cho thao tác nhạy cảm.
- [ ] `tasks.md` cover hết spec, không thừa.
- [ ] Mỗi task ≤ 1 ngày; dependency rõ.
- [ ] Không có payment/chat/offline/auto-compare ngoài scope.

### 12.2 Code

- [ ] Test pass; test mới thực sự bắt được lỗi.
- [ ] Không hard-code `tenantId` từ client.
- [ ] Query có tenant filter hoặc kiểm tra quyền tương đương.
- [ ] Cross-tenant trả 404, không lộ existence.
- [ ] Permission check ở server, không chỉ UI.
- [ ] Audit event đúng actor/tenant/entity.
- [ ] Không log PII/CCCD/token.
- [ ] Migration an toàn; có rollback.
- [ ] Không có code chết/TODO ngoài scope.
- [ ] UI có loading/empty/error/retry.

### 12.3 Archive

- [ ] Tất cả task `[x]`.
- [ ] PR đã merge.
- [ ] `openspec validate --all` pass.
- [ ] Main spec đã sync.
- [ ] Change nằm trong `archive/YYYY-MM-DD-*`.
- [ ] Không còn change active trùng capability.

---

## 13. Lỗi thường gặp

| Lỗi | Hậu quả | Cách tránh |
|---|---|---|
| Propose xong apply luôn | Code theo plan chưa review | Gate G1 bắt buộc |
| Một change quá lớn | Không review nổi, conflict spec | Tách theo capability |
| Sửa main spec trực tiếp | Mất delta/lịch sử | Chỉ sửa main spec qua sync/archive |
| Không tick `tasks.md` | Không biết tiến độ thật | Tick ngay khi task xong |
| Bỏ qua cross-tenant test | Lộ dữ liệu | CI gate + review checklist |
| Thêm scope giữa sprint | Trễ, loãng spec | Ý mới → change mới |
| Chạy archive khi task chưa xong | Spec không khớp code | Gate G3 |
| Dùng project-local skills | Team không thống nhất | Dùng global skills + `openspec init --tools none` |
| Copy cả BRD vào spec | Spec phình, lệch nguồn | Spec chỉ chứa delta requirement |

---

## 14. Onboarding thành viên mới

Trong ngày đầu:

1. Đọc `docs/Business_Requirements/BRD_v1.md` mục 1, 3, 6, 12, 13.
2. Đọc `docs/Flow.md` này.
3. Cài OpenSpec CLI + global skills cho agent.
4. Chạy:
   ```bash
   openspec --version
   openspec list
   openspec validate --all
   ```
5. Đọc một change đã archive để xem mẫu:
   ```bash
   ls openspec/changes/archive/
   openspec show <archived-change>
   ```
6. Làm change đầu tiên với vai trò shadow: propose một change nhỏ, review với Tech Lead, apply, archive.

Tiêu chí onboard xong:

- Tự tạo được một change proposal đúng format.
- Biết phân biệt `proposal.md`, `specs/`, `design.md`, `tasks.md`.
- Biết khi nào dùng `update-change`, `sync-specs`.
- Biết chạy `openspec validate --all`.

---

## 15. Tóm tắt một dòng

> **BRD chốt “làm gì”. OpenSpec chốt “change này làm gì, done nghĩa là gì, task nào tiếp theo”. Code chỉ bắt đầu sau khi plan được duyệt; archive chỉ sau khi code merge và test xanh.**
