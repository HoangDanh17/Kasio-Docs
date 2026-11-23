# Nền tảng SaaS Quản lý & Cho thuê Phòng trọ
## Tài liệu Yêu cầu Nghiệp vụ (BRD) — v1.6

| Thuộc tính | Giá trị |
|---|---|
| Phiên bản | **1.6** (baseline MVP + tech stack web responsive; bỏ mobile) |
| Ngày phát hành | 2026-11-23 |
| Trạng thái | Baseline duy nhất; đã chốt nghiệp vụ MVP và tech stack (D-14, mục 1.7) |
| Lịch sử | 1.0 (2026-11-21) nghiệp vụ baseline; 1.1 (2026-11-22) chốt tech stack; 1.2 (2026-11-22) làm rõ bàn giao, kết thúc Lease, người ở, thanh toán, audit PII; 1.3 (2026-11-22) audit toàn bộ Staff, mọi GET đọc MongoDB, giải thích D-15/D-20; 1.4 (2026-11-22) audit mọi actor đã xác thực, Owner xem audit của mình; 1.5 (2026-11-22) CAP outbox cho đồng bộ write→read; 1.6 (2026-11-23) bỏ mobile, toàn bộ actor dùng một web app responsive |
| Nguồn | Quyết định đã chốt trong tài liệu này; bản nháp v0.1 đã xóa khỏi repo (còn trong git history) |
| Người sở hữu | Product Owner |
| Đối tượng đọc | Product Owner, Backend/Frontend Engineer, QA, người review kiến trúc |
| Phạm vi tài liệu | Nghiệp vụ, quy tắc, trạng thái, NFR, tiêu chí chấp nhận, lộ trình cấp epic/sprint |
| Ngoài phạm vi tài liệu | Thiết kế kỹ thuật chi tiết (API contract, ERD vật lý, hạ tầng, CI/CD) — tạo ở Sprint 0 |

> Đây là **baseline duy nhất** cho nghiệp vụ MVP. Bản nháp v0.1 đã được hợp nhất vào tài liệu này và xóa khỏi repo để tránh đọc nhầm; lịch sử vẫn còn trong git.

### Quy ước

- **BẮT BUỘC**: điều kiện không thể bỏ qua trong MVP.
- **NÊN**: nên làm nếu không đánh đổi tiến độ; có thể chuyển sang v1.1.
- **KHÔNG**: nằm ngoài phạm vi, không được tự ý thêm.
- ID: `FR-*` yêu cầu chức năng, `BR-*` quy tắc nghiệp vụ, `NFR-*` yêu cầu phi chức năng, `AC-*` tiêu chí chấp nhận, `D-*` quyết định đã chốt, `OD-*` quyết định còn mở.
- Mọi yêu cầu `Must` phải truy vết được tới ít nhất một `AC-*` (trực tiếp hoặc theo nhóm tại Phụ lục C); mọi `AC-*` phải kiểm thử được.

---

## 1. Tổng quan

### 1.1 Bối cảnh

Thị trường phòng trọ/nhà trọ nhỏ tại Việt Nam vận hành chủ yếu bằng sổ tay, Excel, Zalo:

- Chủ trọ khó quản lý đồng thời nhiều nhà, nhiều phòng, nhiều khách.
- Việc đăng tin phòng trống phân tán, thiếu kênh chung, khó kiểm chứng.
- Tranh chấp khi trả phòng vì không có bằng chứng tình trạng phòng lúc nhận.
- Chủ trọ ở xa khó thông báo đồng loạt, khó theo dõi điện nước, thanh toán.
- Khách thuê không có nơi xem hợp đồng, hóa đơn, lịch sử thanh toán rõ ràng.

Nền tảng giải quyết bằng một **SaaS multi-tenant** cho chủ trọ, kèm **marketplace công khai** cho người tìm phòng, **hợp đồng điện tử mức xác nhận trên web**, **biên bản tình trạng phòng có ảnh**, **hóa đơn điện nước**, **thông báo đẩy** và **ticket báo sự cố**.

### 1.2 Mục tiêu

**Mục tiêu nghiệp vụ**

- **G1**: Số hóa toàn bộ vòng đời thuê: phòng trống → tin đăng → hợp đồng → nhận phòng → hóa đơn hàng tháng → trả phòng.
- **G2**: Tạo bằng chứng ảnh có thời gian cho tình trạng phòng và chỉ số điện/nước, giảm tranh chấp.
- **G3**: Cung cấp một kênh chung để người tìm phòng tìm và liên hệ chủ trọ.
- **G4**: Cho chủ trọ vận hành từ xa qua thông báo theo Property và phân quyền cho nhân viên.
- **G5**: Một tài khoản, một web app responsive cho Owner, Staff và Renter; marketplace dùng được không cần đăng nhập.

**Mục tiêu học tập (dự án cá nhân)**

- **G6**: Thực hành multi-tenancy cách ly dữ liệu, RBAC có phạm vi, audit log, state machine, upload ảnh, background job, push notification và kiểm thử bảo mật.

### 1.3 Tiêu chí thành công

| ID | Tiêu chí | Ngưỡng đo | Cách đo |
|---|---|---|---|
| SC-01 | Owner tự hoàn tất onboarding → Property → Room → tin đăng | ≤ 15 phút, không cần hỗ trợ | Usability test với 3–5 người |
| SC-02 | Một vòng thuê end-to-end chạy được trên web | 100% bước, không dùng Excel/Zalo | UAT kịch bản E2E |
| SC-03 | Rò rỉ dữ liệu giữa hai tenant | 0 trường hợp | Bộ test cách ly tenant trong CI |
| SC-04 | Sai trạng thái hóa đơn/thanh toán | 0 trường hợp | Test trạng thái + E2E |
| SC-05 | Hiệu năng API | p95 đọc ≤ 300 ms, ghi ≤ 800 ms ở 200 người dùng đồng thời | Load test |
| SC-06 | Truy vết thao tác nhạy cảm | 100% có audit event | Kiểm tra audit log |
| SC-07 | Pilot | 5–10 Owner, ≥ 50 phòng, 3 tháng, không có lỗi P0/P1 kéo dài > 24 giờ | Pilot report |

### 1.4 Phạm vi

| Trong phạm vi MVP | Ngoài phạm vi MVP |
|---|---|
| Đăng ký/đăng nhập Owner, Staff, Renter; một tài khoản dùng nhiều vai trò | Đăng nhập mạng xã hội, SSO, OTP SMS |
| Tenant tự động cho Owner; cách ly dữ liệu theo `TenantId` | Schema/database riêng cho từng Owner |
| Property, Room, bảng giá điện/nước/dịch vụ | Quản lý tài sản cố định, khấu hao |
| Tin đăng, marketplace, tìm kiếm, yêu cầu xem phòng | Tin nổi bật, quảng cáo trả phí, SEO web công khai |
| Duyệt tin, feedback từ chối, bản nháp sửa đổi | Workflow kiểm duyệt nhiều cấp |
| Hợp đồng, người ở, CCCD, xác nhận trên web | Chữ ký số có giá trị pháp lý/chứng thực |
| Biên bản check-in/check-out có ảnh | So sánh ảnh tự động, AI phát hiện hư hỏng |
| Nhập chỉ số điện/nước, Renter xác nhận ảnh | Đồng hồ thông minh, IoT |
| Hóa đơn, minh chứng chuyển khoản, Owner xác nhận | Thanh toán online, ví điện tử, cổng ngân hàng, đối soát tự động |
| Thông báo đẩy + inbox, thông báo theo Property | Chat nhóm, chat realtime, SMS/email marketing |
| Ticket báo sự cố | Helpdesk đa cấp, SLA, chat trực tuyến |
| Audit log, phân quyền Staff | Báo cáo doanh thu, dashboard nâng cao, đa ngôn ngữ |
| Một web app responsive cho mọi actor; marketplace công khai không cần đăng nhập | App native iOS/Android; desktop app |

### 1.5 Ràng buộc và giả định

**Ràng buộc**

- Một người phát triển, làm song song với công việc khác; sprint 2 tuần.
- Responsive web-first; một web app cho Owner/Staff/Renter/Seeker; Platform Admin dùng chung web app ở khu vực quản trị.
- Thị trường Việt Nam: tiếng Việt, VND, múi giờ `Asia/Ho_Chi_Minh`.
- **Không có nghiệp vụ tiền bạc giữa Owner và nền tảng**: không phí thành viên, không billing, không subscription, không hoàn phí.
- **Không tích hợp thanh toán**: chuyển khoản ngoài hệ thống; hệ thống chỉ ghi nhận minh chứng và xác nhận.
- Không có offline mode; chỉ chịu mạng yếu bằng retry/upload lại.
- Push notification qua Web Push (FCM) + inbox; email chỉ dùng cho xác thực/khôi phục mật khẩu/lời mời.
- Backend: **C# / ASP.NET Core**, kiến trúc **DDD + CQRS**; **PostgreSQL** là write DB (nguồn sự thật); **MongoDB** là read DB (projection, rebuild được); đồng bộ write→read bằng **CAP (.NET) transactional outbox + event bus**; background job bằng **Hangfire**.
- Web: **Next.js + Tailwind CSS + GSAP**; một web app responsive cho Owner/Staff/Renter/Seeker/Platform Admin.
- Hạ tầng managed: PostgreSQL, MongoDB, object storage S3-compatible; worker Hangfire chạy tách khỏi API.

**Giả định**

- Owner và Renter có thiết bị dùng trình duyệt web có internet; Renter chấp nhận dùng web/link để xác nhận.
- Trường hợp Renter không dùng web được xử lý ngoài hệ thống trong MVP; không thiết kế luồng giấy tờ thay thế.
- Platform Admin có người trực để duyệt tin trong vòng 24 giờ.
- Push có thể trễ/mất; inbox trên web là nguồn sự thật.
- Nội dung hợp đồng do Owner cung cấp; nền tảng không tư vấn pháp lý.

### 1.6 Quyết định đã chốt

| ID | Quyết định | Lý do |
|---|---|---|
| D-01 | Multi-tenant: một backend, schema chung trên PostgreSQL (write DB), tách bằng `TenantId`; MongoDB chỉ là read model rebuild được | Đơn giản vận hành, phù hợp dự án một người |
| D-02 | Không có phí thành viên/billing giữa Owner và nền tảng | Theo câu trả lời mục 10.1; tránh xây nghiệp vụ tiền bạc ngoài phạm vi |
| D-03 | Không tích hợp thanh toán online; chỉ ghi nhận minh chứng + Owner xác nhận | Theo câu trả lời mục 10.5, 10.6; giảm rủi ro pháp lý/kỹ thuật |
| D-04 | Một web app responsive cho Owner/Staff/Renter/Seeker; Platform Admin dùng chung web app ở khu vực quản trị | Một codebase web; responsive thay app native, giảm chi phí phát triển |
| D-05 | Một Staff chỉ thuộc một Owner; Renter một tài khoản dùng nhiều Owner | Theo câu trả lời mục 10.2; đơn giản hóa membership |
| D-06 | Sửa tin đang hiển thị tạo revision chờ duyệt; bản cũ vẫn công khai | Theo câu trả lời mục 10.3; tránh nội dung chưa duyệt lên marketplace |
| D-07 | CCCD là dữ liệu nhạy cảm; Owner cấp quyền cho Staff; archive khi kết thúc | Theo câu trả lời mục 10.4; giảm phơi bày dữ liệu |
| D-08 | Ký hợp đồng ở mức xác nhận trên web, không phải chữ ký số pháp lý | Câu trả lời mục 10.5 không nêu mức ký; chọn mức đơn giản, ghi rõ giới hạn |
| D-09 | Có module Ticket cho Renter báo sự cố | Theo câu trả lời mục 10.7 |
| D-10 | Renter xác nhận ảnh chỉ số điện/nước trước khi phát hành hóa đơn (hoặc quá 72 giờ theo BR-21) | Theo câu trả lời mục 10.5 |
| D-11 | Không so sánh ảnh tự động, không màn hình so sánh trực tiếp | Giữ đúng phạm vi MVP; giảm phức tạp |
| D-12 | Không chat nhóm/chat realtime; chỉ push một chiều + ticket | Giữ đúng phạm vi MVP |
| D-13 | Marketplace chỉ phục vụ bản tin đã duyệt hiện hành | Chống rò rỉ nội dung chưa duyệt |
| D-14 | Tech stack: ASP.NET Core (C#) + DDD/CQRS; PostgreSQL write DB, MongoDB read DB, CAP (.NET) transactional outbox cho đồng bộ write→read, Hangfire cho background job; Next.js + Tailwind CSS + GSAP cho một web app responsive dùng cho mọi actor | Một người làm cần stack quen thuộc, tách read/write để đọc nhanh; CAP giữ outbox cùng transaction PostgreSQL; trade-off CQRS/eventual consistency được ghi rõ ở mục 1.7 |
| D-15 | Check-in lập sau khi Lease `Active`, trước khi bàn giao; biên bản `PendingRenter` không chặn Lease nhưng phải nhắc Renter hàng ngày | Tách ký hợp đồng khỏi biên bản, vẫn giữ bằng chứng trước khi giao phòng |
| D-16 | Chỉ Renter đại diện có tài khoản; người ở cùng là hồ sơ dữ liệu, không đăng nhập trong MVP | Khớp mô hình `Lease.representativeUserId`; tránh mở rộng quyền truy cập ngoài phạm vi |
| D-17 | Hóa đơn `PaymentSubmitted` không bị job chuyển `Overdue`; chỉ `Issued` mới chuyển; hóa đơn chờ xác nhận quá hạn hiển thị cờ trễ | Tránh trạng thái "quá hạn" sai khi Renter đã gửi minh chứng |
| D-18 | Audit không lưu số CCCD, ảnh, token hay mật khẩu; `before`/`after` chỉ chứa field thay đổi đã che PII | Tránh audit trở thành kho dữ liệu nhạy cảm thứ hai |
| D-19 | Quá `endDate` Lease không tự `Terminated`; giữ `EndingSoon` đến khi BR-19 hoàn tất | Không bỏ qua check-out, hóa đơn cuối và hoàn cọc |
| D-20 | Check-out: Owner chỉ được `Terminated` sau khi Renter xác nhận biên bản hoặc quá 72 giờ kể từ khi gửi; quá hạn dùng cờ `unconfirmedCheckout` + lý do + audit | Tránh chặn trả phòng nhưng vẫn có thời gian phản hồi và bằng chứng |
| D-21 | Audit ghi **mọi thao tác của actor đã xác thực** (Owner, Staff, Renter, Platform Admin: đọc/ghi/tải file/xuất PDF) kèm actor, tenant, thời gian, hành động, entity, kết quả; Owner xem được audit của chính mình và activity log của Staff. Hành động công khai có side effect của Seeker ghi audit không danh tính. | Owner giám sát được mình và nhân viên; audit tách application log, append-only, không chứa PII |

**Giải thích D-15 và D-20**

- **D-15 — Check-in và bàn giao:** Lease `Active` ngay khi Owner và Renter ký. Sau đó, trước khi giao chìa khóa, Owner lập biên bản check-in và gửi Renter. Renter xác nhận thì biên bản `Locked`; chưa xác nhận thì vẫn `PendingRenter` và được nhắc hàng ngày. Hệ thống chỉ cho ghi nhận "đã bàn giao" sau khi biên bản đã gửi — không bắt Renter phải xác nhận xong mới được nhận phòng.
- **D-20 — Check-out:** Khi trả phòng, Owner lập biên bản check-out. Renter xác nhận thì khóa ngay. Nếu Renter không phản hồi trong 72 giờ, Owner được khóa với cờ `unconfirmedCheckout` + lý do + audit; trước 72 giờ thì không. Sau khi biên bản khóa, hóa đơn cuối và hoàn cọc xử lý xong thì Lease mới `Terminated`. Renter vẫn xem và phản hồi sau; thay đổi qua phụ lục.

### 1.7 Kiến trúc kỹ thuật đã chốt

| Lớp | Công nghệ | Vai trò |
|---|---|---|
| Backend | C# / ASP.NET Core | API, domain, application, authorization |
| Kiến trúc backend | DDD + CQRS | Aggregate/domain cho write side; command và query tách biệt |
| Write DB | PostgreSQL | Nguồn sự thật: command, transaction, unique/partial index, audit |
| Read DB | MongoDB | Projection/read model: **mọi domain GET/query** (marketplace, danh sách, chi tiết, activity log) |
| Sync write→read | CAP (.NET) | Transactional outbox + event bus; publish sau khi transaction PostgreSQL commit; at-least-once, consumer idempotent; transport chốt ở Sprint 0 |
| Background job | Hangfire (storage PostgreSQL) | Nhắc hạn, chuyển `Overdue`, `EndingSoon`, archive CCCD, retry push, rebuild projection |
| Web | Next.js + Tailwind CSS + GSAP | Một web app responsive cho Owner/Staff/Renter/Seeker/Platform Admin; animation/transition bằng GSAP |
| Object storage | S3-compatible, bucket private | Ảnh tin, CCCD, biên bản, minh chứng |
| Push | Web Push (FCM) | Push notification trên web; inbox là nguồn sự thật |

**Ràng buộc kiến trúc**

- **Write model là nguồn sự thật.** Mọi ràng buộc nghiệp vụ (BR-01, BR-09, BR-10, BR-15, BR-22, BR-25, BR-41) cưỡng chế ở domain + PostgreSQL; MongoDB **không** thay thế ràng buộc.
- **Read model chỉ để đọc và phải rebuild được** từ write DB. Sai lệch read model xử lý bằng rebuild, không sửa tay.
- Projection cập nhật qua **CAP (.NET) transactional outbox**: event được publish sau khi transaction PostgreSQL commit, giao ít nhất một lần (at-least-once); mỗi consumer/projection handler idempotent; lag mục tiêu p95 ≤ 2 giây (NFR-DAT-05). Đây là **đồng bộ bất đồng bộ/eventual consistency**, không phải transaction hai pha; UI hiển thị dữ liệu read model có thể trễ trong khoảng lag này.
- CAP outbox nằm cùng transaction PostgreSQL; chỉ đánh dấu đã publish sau khi transport nhận; retry/backoff, message lỗi quá ngưỡng được giữ lại (dead-letter/retry store) + alert; không xóa outbox trước khi publish.
- **Mọi domain GET/query API chỉ đọc từ MongoDB read model**; query handler **không** query PostgreSQL. Ngoại lệ hạ tầng: auth/session, permission check, idempotency và support-access gate được đọc write DB.
- Command handler chỉ ghi PostgreSQL và phát domain event qua **CAP outbox**; không đọc read model để quyết định ghi.
- Hangfire job gọi command/application handler, không ghi trực tiếp MongoDB; projection chỉ cập nhật qua CAP outbox. Hangfire dùng cho job theo lịch/định kỳ; CAP dùng cho phân phối event và projection, không thay thế nhau.
- Marketplace search (FR-LST-10) và mọi danh sách/GET nghiệp vụ (BR-42), gồm cả activity log (FR-ADT-07), phục vụ từ read model; projection công khai chỉ chứa snapshot `Published`.
- Mọi document read model tenant-scoped có `tenantId`; read repository bắt buộc filter; test cross-tenant áp dụng cho cả read side (NFR-SEC-05).
- Tiền lưu số nguyên 64-bit (đồng) ở cả hai phía; không dùng `double`/floating point (BR-25).
- Hangfire worker chạy tách khỏi API, scale ngang dùng distributed lock; job phải idempotent và retry an toàn (BR-39).
- MongoDB không dùng làm write DB cho bất kỳ aggregate nào trong MVP.
- Toàn bộ MVP chạy trên một web app responsive; marketplace công khai là route không cần đăng nhập, nhưng SEO/quảng cáo vẫn ngoài phạm vi (OD-10).

---

## 2. Thuật ngữ

| Thuật ngữ | Ý nghĩa |
|---|---|
| **Platform** | Nền tảng trung tâm do Product Owner vận hành |
| **Owner** (chủ trọ) | Khách hàng của nền tảng; sở hữu một tenant |
| **Tenant** | Không gian dữ liệu của một Owner; `TenantId` là ID của `OwnerTenant` (1:1 với Owner) |
| **Staff** (nhân viên/quản lý) | Người được Owner mời, làm việc trong tenant của Owner đó; **chỉ thuộc một Owner** |
| **Renter** (khách thuê) | Người đại diện thuê phòng, có tài khoản; có thể thuê nhiều Owner bằng **một tài khoản** |
| **Seeker** (người tìm phòng) | Người xem tin công khai, chưa đăng nhập |
| **Property** (nhà trọ) | Một địa điểm/dãy trọ thuộc một Owner |
| **Room** (phòng) | Một phòng thuộc Property |
| **Listing** (tin đăng) | Tin quảng cáo một phòng trống trên marketplace |
| **Listing Revision** | Bản sửa đổi nội dung tin đăng; bản đã duyệt vẫn hiển thị trong khi bản mới chờ duyệt |
| **Viewing Request** | Yêu cầu liên hệ/đặt lịch xem phòng của Seeker |
| **Lease** (hợp đồng) | Thỏa thuận thuê giữa Owner và Renter cho một Room |
| **Occupant** (người ở) | Người đại diện hoặc người ở cùng trong Lease; **chỉ là hồ sơ dữ liệu, không có tài khoản đăng nhập trong MVP** |
| **Condition Report** (biên bản tình trạng) | Bản ghi tình trạng phòng kèm ảnh tại check-in/check-out |
| **Meter Reading** (chỉ số) | Chỉ số điện/nước của một kỳ, kèm ảnh đồng hồ |
| **Invoice** (hóa đơn) | Hóa đơn tiền phòng + điện + nước + dịch vụ của một kỳ |
| **Payment Proof** (minh chứng thanh toán) | Ảnh biên lai/thông tin chuyển khoản do Renter hoặc Owner tải lên |
| **Ticket** (yêu cầu sự cố) | Yêu cầu báo hỏng/sự cố của Renter cho một Room |
| **Audit Event** | Bản ghi bất biến của một thao tác quan trọng |
| **Suspended** | Trạng thái Owner bị Platform Admin khóa |

---

## 3. Vai trò và phân quyền

### 3.1 Actors

| Actor | Kênh | Trách nhiệm chính |
|---|---|---|
| **Platform Admin** | Web (responsive) | Quản lý Owner, khóa/mở khóa, duyệt tin, bật miễn duyệt, xử lý báo cáo, thống kê nền tảng |
| **Owner** | Web (responsive) | Quản lý Property/Room/giá, đăng tin, hợp đồng, biên bản, điện nước, hóa đơn, nhân viên, thông báo |
| **Staff** | Web (responsive) | Làm việc trong tenant của một Owner theo role + phạm vi Property được giao |
| **Renter** | Web (responsive) | Xem/ký hợp đồng, xác nhận biên bản & chỉ số, xem hóa đơn, gửi minh chứng, tạo ticket |
| **Seeker** | Web công khai (không đăng nhập) | Tìm tin, xem chi tiết, gửi yêu cầu xem phòng |

### 3.2 Mô hình danh tính

- Một **User** toàn nền tảng, định danh bằng email hoặc số điện thoại duy nhất.
- Một User có thể đồng thời:
  - Là Owner của tenant mình tạo.
  - Là Renter trong lease của bất kỳ Owner nào.
  - Là Staff của **đúng một** Owner.
- **Staff không được thuộc nhiều Owner.** Nếu muốn làm cho Owner khác, phải rời Owner cũ hoặc dùng tài khoản khác.
- Quyền được kiểm tra theo **membership** (Owner/Staff) + **role** + **property scope**, không chỉ theo vai trò toàn cục.
- Platform Admin là vai trò nền tảng, không thuộc tenant.

### 3.3 Ma trận quyền mức nghiệp vụ

| Năng lực | Owner | Staff | Platform Admin | Renter | Seeker |
|---|---|---|---|---|---|
| Quản lý Property/Room/bảng giá | Toàn tenant | Theo quyền + phạm vi | Hỗ trợ có audit | — | — |
| Đăng/sửa tin | Toàn tenant | Theo quyền | Duyệt/từ chối | — | — |
| Duyệt tin, bật miễn duyệt | — | — | Có | — | — |
| Tạo/chấm dứt hợp đồng | Toàn tenant | Theo quyền | — | Ký/xem hợp đồng của mình | — |
| Xem CCCD | Có | Chỉ khi được cấp quyền nhạy cảm | Chỉ khi support access có lý do | Chỉ ảnh của mình | — |
| Biên bản check-in/out | Toàn tenant | Theo quyền | — | Xác nhận/phản hồi | — |
| Nhập chỉ số điện/nước | Toàn tenant | Theo quyền | — | Xác nhận/phản hồi | — |
| Tạo hóa đơn | Toàn tenant | Theo quyền | — | Xem hóa đơn của mình | — |
| Xác nhận thanh toán | Có | Chỉ khi được cấp quyền nhạy cảm | — | Gửi minh chứng | — |
| Gửi thông báo Property | Có | Theo quyền | — | Nhận | — |
| Quản lý Staff/role | Có | — | — | — | — |
| Ticket | Xem/xử lý | Theo quyền | — | Tạo/xem ticket của mình | — |
| Audit log tenant | Có | Theo quyền | Có (toàn nền tảng) | — | — |
| Khóa/mở Owner | — | — | Có | — | — |

> Quyền chi tiết theo mã ở mục 10.

### 3.4 Role mặc định

| Role | Phạm vi | Quyền mặc định | Quyền nhạy cảm |
|---|---|---|---|
| `owner` | Toàn tenant | Toàn bộ quyền tenant | `document.cccd.view`, `payment.confirm`, `lease.terminate`, `staff.manage`, `tariff.write` |
| `manager` | Property được giao | Property/Room, tin đăng, hợp đồng, biên bản, chỉ số, hóa đơn (trừ xác nhận thanh toán), ticket, thông báo, audit read | Không mặc định |
| `meter_staff` | Property được giao | Xem phòng, nhập chỉ số, xem/xử lý ticket | Không |
| `support_staff` | Property được giao | Xem phòng/hợp đồng/hóa đơn, xử lý ticket, gửi thông báo | Không |

- Owner được tạo role tùy chỉnh và cấp quyền, nhưng **chỉ được cấp quyền mà Owner đang có**.
- Quyền nhạy cảm phải bật riêng, có cảnh báo, và ghi audit khi cấp/thu hồi.
- Staff bị xóa/khóa phải mất hiệu lực ngay; không chờ token hết hạn.

---

## 4. Các phân hệ nghiệp vụ

### 4.1 Tài khoản, tenant và truy cập

- **FR-ACC-01**: Một tài khoản toàn nền tảng; đăng nhập bằng email hoặc số điện thoại + mật khẩu.
- **FR-ACC-02**: Owner tự đăng ký; hệ thống tạo tenant ngay; tài khoản `Active` ngay, **không có bước đóng phí**.
- **FR-ACC-03**: Owner mời Staff bằng email/số điện thoại; gán role + danh sách Property. Staff chấp nhận lời mời; hệ thống từ chối nếu người đó đã là Staff của Owner khác.
- **FR-ACC-04**: Owner mời Renter vào Lease bằng link/token; Renter đăng ký hoặc đăng nhập để chấp nhận.
- **FR-ACC-05**: Người dùng xem thiết bị đang đăng nhập, đăng xuất từng thiết bị hoặc tất cả; đổi mật khẩu thu hồi toàn bộ refresh token.
- **FR-ACC-06**: Platform Admin xem danh sách Owner, khóa/mở khóa kèm lý do bắt buộc; mọi thao tác có audit.
- **FR-ACC-07**: Platform Admin duyệt/từ chối tin, bật/tắt miễn duyệt cho từng Owner, xử lý báo cáo vi phạm.
- **FR-ACC-08**: Platform Admin chỉ xem dữ liệu tenant qua **support access** có lý do, thời hạn tối đa 24 giờ, mặc định chỉ đọc, có audit.
- **FR-ACC-09**: Cập nhật hồ sơ cá nhân; email/số điện thoại phải duy nhất; đổi số điện thoại/email cần xác thực lại.

### 4.2 Property, Room và bảng giá

- **FR-PRP-01**: Owner/Staff có quyền tạo, sửa, lưu trữ Property (tên, địa chỉ, tiện ích chung, nội quy, ghi chú).
- **FR-PRP-02**: Tạo/sửa Room (mã phòng, diện tích, giá thuê, tiền cọc, tiện nghi, trạng thái); mã phòng duy nhất trong Property.
- **FR-PRP-03**: Danh mục đơn giá: điện, nước, internet, rác, giữ xe, dịch vụ khác; mỗi mục là **cố định** hoặc **theo chỉ số**; có ngày hiệu lực.
- **FR-PRP-04** *(NÊN)*: Tạo nhanh nhiều Room theo mẫu (số tầng, dải số phòng).
- **FR-PRP-05**: Trang chi tiết Room hiển thị hợp đồng hiện tại, tin đăng, chỉ số gần nhất, hóa đơn gần nhất, ticket mở.
- **FR-PRP-06**: Lưu trữ Property chỉ khi không còn Room đang thuê, không còn tin đang hiển thị; dữ liệu lịch sử vẫn tra cứu được.
- **FR-PRP-07**: Room ở trạng thái `Maintenance` không thể đăng tin hoặc tạo hợp đồng.

### 4.3 Tin đăng và marketplace

- **FR-LST-01**: Tạo tin từ Room `Vacant`; mỗi Room tối đa một tin đang hoạt động (chưa đóng).
- **FR-LST-02**: Ảnh 1–20 ảnh/tin, JPEG/PNG/WebP, tối đa 10 MB/ảnh; client nén trước khi upload; server kiểm tra magic bytes, strip EXIF, tạo thumbnail; Owner chọn ảnh bìa và sắp thứ tự.
- **FR-LST-03**: Mặc định tin phải được Platform Admin duyệt trước khi hiển thị; Owner có cờ `autoApprove` thì tin vào thẳng `Published`.
- **FR-LST-04**: Khi từ chối, Platform Admin bắt buộc nhập lý do; Owner thấy feedback, sửa và gửi lại.
- **FR-LST-05**: Sửa tin đang `Published` không làm thay đổi bản công khai ngay; hệ thống tạo **Listing Revision** ở trạng thái chờ duyệt. Bản đã duyệt tiếp tục hiển thị đến khi revision được duyệt.
- **FR-LST-06**: Mỗi tin chỉ có tối đa một revision đang chờ; Owner có thể hủy revision để sửa lại từ đầu.
- **FR-LST-07**: Tin tự đóng khi Room không còn `Vacant` (đã giữ chỗ/đang thuê/sửa chữa) hoặc khi Owner đóng thủ công.
- **FR-LST-08**: Marketplace công khai trên web: lọc theo tỉnh/thành, quận/huyện, khoảng giá, diện tích, tiện nghi, ngày vào ở; sắp xếp mới nhất/giá; phân trang.
- **FR-LST-09**: Seeker gửi yêu cầu xem phòng (tên, số điện thoại, lời nhắn, thời gian mong muốn); Owner nhận thông báo và quản lý trạng thái `New → Contacted → Scheduled → Completed/Closed/Cancelled`.
- **FR-LST-10**: Marketplace chỉ trả về **bản đã duyệt hiện hành** của tin `Published`; không trả draft, pending, rejected, hay dữ liệu tenant khác. Dữ liệu đọc từ read model MongoDB; độ trễ tối đa theo NFR-DAT-05.
- **FR-LST-11**: Không có tin nổi bật/quảng cáo trả phí; mọi tin được xử lý như nhau.
- **FR-LST-12**: Owner có tùy chọn ẩn số nhà/địa chỉ chính xác; khi ẩn, chỉ hiển thị phường/quận/tỉnh; địa chỉ đầy đủ gửi khi Owner chấp nhận yêu cầu xem phòng.
- **FR-LST-13** *(NÊN)*: Seeker báo cáo tin vi phạm; Platform Admin xử lý và có audit.

### 4.4 Hợp đồng thuê

- **FR-LSE-01**: Owner/Staff có quyền tạo Lease từ Room `Vacant`: Renter, thời hạn, giá thuê, tiền cọc, chu kỳ thanh toán, ngày đến hạn, đơn giá điện/nước/dịch vụ, điều khoản/nội quy.
- **FR-LSE-02**: Mời Renter bằng số điện thoại/email/link; token có hạn 7 ngày, dùng một lần; Renter chưa có tài khoản thì đăng ký trong luồng.
- **FR-LSE-03**: Khai báo người đại diện + người ở cùng: họ tên, ngày sinh, số CCCD, số điện thoại, vai trò; đính ảnh CCCD mặt trước/sau. Ảnh CCCD là dữ liệu nhạy cảm. Chỉ người đại diện có tài khoản Renter; người ở cùng chỉ là hồ sơ (D-16).
- **FR-LSE-04**: Owner xác nhận nội dung và ký trước; Renter xem bản hợp đồng, tick đồng ý và xác nhận; Lease chỉ `Active` khi cả hai đã ký.
- **FR-LSE-05**: Hệ thống tạo bản PDF bất biến của hợp đồng tại thời điểm ký, kèm hash, timestamp, user/device; tải lại phải khớp hash.
- **FR-LSE-06**: Sau khi ký, không sửa trực tiếp nội dung; thay đổi giá/thời hạn/điều khoản phải tạo phụ lục hoặc phiên bản mới, có xác nhận của các bên.
- **FR-LSE-07**: Gia hạn tạo Lease mới kế tiếp; ngày kết thúc của Lease cũ không đổi. Quá ngày kết thúc không tự động chuyển `Terminated`: Lease giữ `EndingSoon` cho đến khi BR-19 hoàn tất.
- **FR-LSE-08**: Renter gửi yêu cầu trả phòng; Owner xác nhận; hệ thống tạo checklist check-out và hóa đơn cuối.
- **FR-LSE-09**: Job hàng ngày đánh dấu `EndingSoon` trước ngày hết hạn 30 ngày; gửi thông báo cho Owner và Renter.
- **FR-LSE-10**: Một Room chỉ có tối đa một Lease `Active` tại một thời điểm.
- **FR-LSE-11**: Renter xem tất cả Lease của mình trên nhiều Owner trong cùng một tài khoản.
- **FR-LSE-12**: Ký điện tử ở mức **xác nhận trên web**, không phải chữ ký số có giá trị pháp lý; ghi rõ điều này trong hợp đồng và màn hình xác nhận.
- **FR-LSE-13**: Khi Lease kết thúc, ảnh CCCD chuyển sang trạng thái lưu trữ, ẩn khỏi giao diện thường và khỏi Staff; Renter đại diện vẫn xem được ảnh CCCD của chính mình; Owner có quyền nhạy cảm và Platform Admin qua support access xem được ảnh archive, có audit.
- **FR-LSE-14**: Staff chỉ thấy Lease thuộc Property được giao và chỉ thao tác trong phạm vi quyền.

### 4.5 Biên bản tình trạng phòng

- **FR-CND-01**: Tạo biên bản check-in gắn với Lease **sau khi Lease `Active` và trước khi bàn giao phòng**; các khu vực mặc định: tường, sàn, cửa, nhà vệ sinh, nhà bếp, ban công, thiết bị, đồ đạc, khác; Owner thêm khu vực tùy chỉnh.
- **FR-CND-02**: Mỗi khu vực có ghi chú, tình trạng (`Tốt`/`Trung bình`/`Hư hỏng`) và 1–10 ảnh; ảnh có timestamp server và watermark hiển thị.
- **FR-CND-03**: Renter xem biên bản, xác nhận hoặc phản hồi bổ sung; nếu phản hồi, Owner sửa và gửi lại.
- **FR-CND-04**: Biên bản `Locked` (cả hai xác nhận, hoặc Owner chốt theo FR-CND-11 với cờ `unconfirmedCheckout`) là **bất biến**; thay đổi phải tạo phụ lục, không sửa ảnh/ghi chú cũ.
- **FR-CND-05**: Check-out dùng cùng danh sách khu vực; hiển thị ảnh check-in và check-out theo từng khu vực để người dùng **tự đối chiếu bằng mắt**. Không có màn hình so sánh trực tiếp, không auto-diff.
- **FR-CND-06**: Check-out ghi nhận hư hỏng phát sinh, chi phí khấu trừ đề xuất, ghi chú; Renter xác nhận hoặc phản hồi.
- **FR-CND-07**: Ghi nhận hoàn cọc: số tiền cọc, khấu trừ, số tiền hoàn, hình thức, ghi chú; chỉ là bản ghi, không xử lý chuyển tiền.
- **FR-CND-08**: Ảnh biên bản không được chỉnh sửa sau khi chốt; mọi ảnh có metadata thời gian, người tải, khu vực.
- **FR-CND-09**: Xuất PDF biên bản check-in/check-out để lưu trữ/chia sẻ.
- **FR-CND-10**: Bàn giao phòng chỉ được ghi nhận hoàn tất sau khi biên bản check-in đã gửi Renter; biên bản `PendingRenter` không chặn Lease `Active` nhưng hệ thống nhắc Renter hàng ngày đến khi xác nhận hoặc phản hồi.
- **FR-CND-11**: Nếu Renter không phản hồi biên bản check-out trong **72 giờ** kể từ khi gửi, Owner được chốt biên bản với cờ `unconfirmedCheckout`, lý do và audit; Renter vẫn xem được và phản hồi sau, thay đổi qua phụ lục.

### 4.6 Chỉ số điện nước, hóa đơn và thanh toán

- **FR-MTR-01**: Owner/Staff nhập chỉ số điện và nước theo kỳ: chỉ số trước (tự lấy từ kỳ trước), chỉ số mới, ảnh đồng hồ, ghi chú, ngày ghi.
- **FR-MTR-02**: Chỉ số mới phải ≥ chỉ số trước. Ngoại lệ thay đồng hồ: bật cờ `meterReplaced`, nhập chỉ số mới bắt đầu lại, bắt buộc ghi chú + ảnh; có audit.
- **FR-MTR-03**: Sau khi gửi, Renter nhận thông báo, xem ảnh và xác nhận hoặc phản hồi. Trạng thái: `Draft → PendingRenter → Confirmed/Disputed`.
- **FR-MTR-04**: Hóa đơn chỉ được tạo từ chỉ số `Confirmed`. Nếu Renter không phản hồi trong **72 giờ**, Owner được phép phát hành hóa đơn với cờ `unconfirmedReading`, có audit và thông báo; Renter vẫn có thể phản hồi sau đó.
- **FR-MTR-05**: Hóa đơn gồm các dòng: tiền phòng, điện, nước, internet, rác, giữ xe, dịch vụ khác; mỗi dòng có số lượng, đơn giá, thành tiền; đơn giá được snapshot tại thời điểm phát hành.
- **FR-MTR-06**: Hóa đơn có kỳ, ngày phát hành, ngày đến hạn, tổng tiền; mặc định đến hạn ngày 5 của tháng kế tiếp hoặc theo Lease.
- **FR-MTR-07**: Hóa đơn đã phát hành là bất biến; điều chỉnh bằng cách void và phát hành hóa đơn thay thế, có lý do + audit; không xóa.
- **FR-MTR-08**: Renter hoặc Owner/Staff tải minh chứng chuyển khoản: số tiền, thời gian, mã giao dịch (nếu có), ảnh biên lai/ghi chú; hóa đơn chuyển `PaymentSubmitted`.
- **FR-MTR-09**: Chỉ người có quyền `payment.confirm` được xác nhận thanh toán; nếu từ chối, bắt buộc lý do; hóa đơn về trạng thái trước đó (`Issued` hoặc `Overdue`).
- **FR-MTR-10**: Trạng thái hóa đơn: `Issued` (chưa thanh toán), `PaymentSubmitted`, `Paid`, `Overdue`, `Void`.
- **FR-MTR-11**: Job hàng ngày chỉ chuyển hóa đơn `Issued` quá hạn sang `Overdue`; hóa đơn `PaymentSubmitted` giữ nguyên trạng thái và hiển thị cờ trễ theo `dueDate`; gửi nhắc trước hạn 3 ngày, đúng hạn, sau hạn 3 ngày và 7 ngày.
- **FR-MTR-12**: Không tích hợp thanh toán online/ví/cổng ngân hàng; không xử lý hoàn tiền tự động.
- **FR-MTR-13**: Xuất PDF hóa đơn và biên nhận xác nhận thanh toán.
- **FR-MTR-14**: MVP không hỗ trợ thanh toán một phần; số tiền xác nhận phải bằng tổng hóa đơn, trừ khi Owner ghi đè có lý do + audit.
- **FR-MTR-15**: Renter xem hóa đơn theo Lease và theo tháng, kèm bảng giá đang áp dụng cho Lease của mình; Owner xem theo Property/Room/kỳ; có bộ lọc trạng thái.
- **FR-MTR-16**: Renter đại diện chỉ thấy hóa đơn thuộc Lease mà mình là `representativeUserId`; người ở cùng không có tài khoản và không truy cập trực tiếp.

### 4.7 Thông báo và liên lạc

- **FR-NTF-01**: Kênh: Web Push (FCM) + inbox trên web. Email chỉ cho xác thực/khôi phục mật khẩu/lời mời.
- **FR-NTF-02**: Sự kiện: hợp đồng mới, hợp đồng sắp hết hạn, hóa đơn mới, nhắc thanh toán, thanh toán được xác nhận/từ chối, chỉ số mới, biên bản mới, ticket cập nhật, thông báo chung.
- **FR-NTF-03**: Owner/Staff có quyền gửi thông báo theo Property; xem trước nội dung; gửi một lần đến tất cả Renter đại diện đang có Lease `Active` trong Property; có audit.
- **FR-NTF-04**: Mỗi thông báo có deep link tới entity liên quan; khi mở phải kiểm tra lại quyền.
- **FR-NTF-05**: Người dùng tùy chọn tắt thông báo theo nhóm (tin đăng, ticket, thông báo chung); thông báo giao dịch (hợp đồng/hóa đơn/thanh toán) không được tắt.
- **FR-NTF-06**: Lưu trạng thái gửi `queued/sent/failed`, retry tối đa 3 lần; inbox vẫn hoạt động khi push thất bại.
- **FR-NTF-07**: Không có chat nhóm/chat realtime; phản hồi đi qua ticket hoặc yêu cầu xem phòng.
- **FR-NTF-08**: Không gửi SMS; không email marketing.

### 4.8 Ticket báo sự cố

- **FR-TKT-01**: Renter tạo ticket cho Room đang thuê; không tạo cho Room khác.
- **FR-TKT-02**: Trường: tiêu đề, mô tả, danh mục (điện, nước, cơ sở vật chất, an ninh, khác), ảnh (0–10), mức độ do Renter chọn (`Thấp/Trung bình/Cao`).
- **FR-TKT-03**: Trạng thái: `Open → Acknowledged → InProgress → Resolved → Closed`; có thể `Open → Closed` nếu trùng/hủy.
- **FR-TKT-04**: Hai bên bình luận; Owner/Staff có thể ghi chú nội bộ không hiển thị cho Renter.
- **FR-TKT-05**: Mỗi thay đổi trạng thái/bình luận gửi thông báo cho bên còn lại.
- **FR-TKT-06**: Owner/Staff chỉ thấy ticket thuộc Property được giao; Renter chỉ thấy ticket của mình.
- **FR-TKT-07**: Renter mở lại ticket trong 7 ngày sau khi `Resolved`; quá hạn phải tạo ticket mới.
- **FR-TKT-08**: Không có chat realtime/SLA trong MVP.

### 4.9 Audit log

- **FR-ADT-01**: Ghi audit cho **mọi thao tác của actor đã xác thực** (Owner, Staff, Renter, Platform Admin): đọc/xem, ghi, tải file, xuất PDF; kèm hành động công khai có side effect của Seeker (gửi yêu cầu xem, báo cáo tin) ở dạng không danh tính. Các sự kiện quan trọng vẫn audit theo §11.1: đăng nhập thất bại, đổi quyền, mời/xóa Staff, tạo/sửa/xóa Property/Room/giá, duyệt/từ chối tin, ký hợp đồng, chốt biên bản, xem CCCD, nhập/sửa chỉ số, phát hành/void hóa đơn, xác nhận/từ chối thanh toán, gửi thông báo Property.
- **FR-ADT-02**: Mỗi event gồm: `id`, `occurredAt`, `actorUserId`, `actorRole`, `tenantId`, `action`, `entityType`, `entityId`, `before`, `after`, `ip`, `userAgent`, `requestId`, `reason`. `before`/`after` chỉ chứa metadata/field thay đổi; không chứa số CCCD, ảnh, token, mật khẩu; giá trị nhạy cảm phải được che (D-18).
- **FR-ADT-03**: Audit là append-only; không có API sửa/xóa.
- **FR-ADT-04**: Owner xem audit của tenant, gồm activity log của **chính mình** và của từng Staff (lọc theo actor/thời gian/hành động); Staff có `audit.read` xem theo quyền; Platform Admin xem toàn nền tảng; Renter không xem audit nội bộ.
- **FR-ADT-05**: Mọi lần xem ảnh CCCD, support access, xác nhận thanh toán, đổi giá, đổi quyền đều tạo audit.
- **FR-ADT-06** *(NÊN)*: Xuất CSV audit theo khoảng thời gian cho Owner.
- **FR-ADT-07**: Activity log (Owner/Staff/Platform Admin) đọc từ read model MongoDB; mỗi bản ghi có actor, hành động, entity, thời gian, kết quả; không chứa PII hay nội dung file.

---

## 5. Luồng nghiệp vụ chính

### 5.1 Onboarding Owner

1. Owner đăng ký bằng email/số điện thoại + mật khẩu.
2. Hệ thống tạo User + Tenant + membership `owner`; tài khoản `Active` ngay (không đóng phí).
3. Owner tạo Property → thêm Room → thiết lập bảng giá.
4. Owner mời Staff (nếu có) và gán role/phạm vi.
5. Owner có thể đăng tin hoặc tạo hợp đồng ngay.

**Kết quả**: tenant sẵn sàng; audit ghi nhận việc tạo tenant/property/room.

### 5.2 Đăng tin → Seeker → xem phòng

1. Owner chọn Room `Vacant`, chụp/tải ảnh, nhập giá/mô tả/tiện nghi/ngày vào ở.
2. Gửi tin → `PendingReview` (hoặc `Published` nếu được miễn duyệt).
3. Platform Admin duyệt → `Published`; từ chối → `Rejected` + feedback.
4. Seeker tìm/lọc, xem chi tiết, gửi yêu cầu xem phòng.
5. Owner nhận thông báo, liên hệ, đặt lịch; cập nhật trạng thái yêu cầu.
6. Owner chốt khách → tạo Lease; Room chuyển `Occupied`; tin tự đóng.

### 5.3 Tạo hợp đồng, giao phòng

1. Owner tạo Lease từ Room `Vacant`, khai báo Renter + người ở + CCCD + điều khoản.
2. Owner ký/xác nhận.
3. Renter mở link, đăng nhập/đăng ký, xem hợp đồng, tick đồng ý, ký.
4. Lease `Active`; hệ thống tạo PDF + hash; Room `Occupied`; tin đóng.
5. Trước khi bàn giao, Owner lập biên bản check-in theo khu vực và gửi Renter (biên bản không chặn Lease `Active`).
6. Renter xác nhận hoặc phản hồi; biên bản `Locked` khi cả hai đồng ý.
7. Ghi nhận bàn giao phòng sau khi biên bản đã gửi; Renter bắt đầu nhận thông báo của Property.

### 5.4 Chu kỳ hàng tháng

1. Cuối kỳ, Owner/Staff nhập chỉ số điện/nước + ảnh đồng hồ.
2. Renter nhận thông báo, xem ảnh, xác nhận hoặc phản hồi.
3. Chỉ số `Confirmed` (hoặc quá 72 giờ, Owner phát hành với cờ `unconfirmedReading`).
4. Hệ thống tạo hóa đơn từ đơn giá đã snapshot; gửi thông báo.
5. Renter chuyển khoản ngoài hệ thống → tải minh chứng lên hóa đơn.
6. Hóa đơn `PaymentSubmitted`; Owner kiểm tra và xác nhận → `Paid` (hoặc từ chối kèm lý do → trạng thái trước khi gửi minh chứng: `Issued`/`Overdue`).
7. Quá hạn: job chỉ chuyển `Issued` → `Overdue`; `PaymentSubmitted` giữ nguyên và gắn cờ trễ; gửi nhắc.

### 5.5 Ticket sự cố

1. Renter tạo ticket cho Room đang thuê, mô tả + ảnh.
2. Owner/Staff nhận thông báo, `Acknowledged` → `InProgress`.
3. Trao đổi bình luận/ghi chú nội bộ; cập nhật trạng thái.
4. `Resolved` → Renter xác nhận `Closed` hoặc mở lại trong 7 ngày.

### 5.6 Trả phòng

1. Renter gửi yêu cầu trả phòng (hoặc Lease hết hạn).
2. Owner xác nhận, tạo biên bản check-out theo cùng khu vực.
3. Owner/Renter đối chiếu ảnh thủ công; ghi hư hỏng/khấu trừ.
4. Chốt hóa đơn cuối (điện nước kỳ cuối + khấu trừ nếu có).
5. Ghi nhận hoàn cọc (chỉ bản ghi, không chuyển tiền); Lease `Terminated` khi BR-19 hoàn tất.
6. Hệ thống archive CCCD, đóng quyền Staff với tài liệu; Room về `Vacant`; Owner có thể đăng tin lại.

---

## 6. Quy tắc nghiệp vụ

### 6.1 Cách ly tenant và truy cập

| ID | Quy tắc | Cưỡng chế |
|---|---|---|
| BR-01 | Mọi bảng (PostgreSQL) và document (MongoDB) thuộc Owner phải có `TenantId`; tenant suy ra từ membership đã xác thực, **không nhận `tenantId` từ client**. | Global query filter (EF Core) cho write model + filter bắt buộc ở read repository + test cross-tenant |
| BR-02 | Truy cập chéo tenant trả `404`, không trả `403`, để không lộ sự tồn tại của dữ liệu. | Middleware/authorization test |
| BR-03 | Renter chỉ đọc dữ liệu qua quan hệ Lease mà mình là người đại diện; không có quyền quét dữ liệu tenant. | Query theo `Lease.representativeUserId` |
| BR-04 | Platform Admin chỉ xem dữ liệu tenant qua support access có lý do, tối đa 24 giờ, mặc định read-only, có audit. | Access gate + audit |
| BR-05 | Một Staff chỉ thuộc một Owner; nếu đã là Staff nơi khác, từ chối lời mời. | Unique membership constraint |
| BR-06 | Một User có một tài khoản; email/số điện thoại duy nhất; không hỗ trợ gộp tài khoản trong MVP. | Unique index |
| BR-07 | Owner `Active` ngay khi đăng ký; không có billing/phí nền tảng; Platform Admin có thể `Suspended` kèm lý do. | State machine + audit |
| BR-08 | Owner `Suspended`: không tạo mới Property/Room/tin/Lease, không đổi giá; **vẫn được nhập chỉ số, phát hành hóa đơn, xác nhận thanh toán, xử lý biên bản/check-out và ghi nhận hoàn cọc cho Lease hiện hữu** để không gián đoạn nghĩa vụ thuê; Renter vẫn xem hợp đồng/hóa đơn, gửi minh chứng, tạo ticket; Staff tiếp tục thao tác trên Lease hiện hữu theo quyền. | Authorization theo trạng thái tenant |
| BR-48 | Chỉ Owner chính có `staff.manage` và `tenant.settings.write`; hai quyền này không cấp cho Staff, kể cả qua role tùy chỉnh. | Permission grant check |

### 6.2 Phòng và tin đăng

| ID | Quy tắc | Cưỡng chế |
|---|---|---|
| BR-09 | Một Room chỉ có tối đa một Lease `Active`. | Partial unique index `(room_id) WHERE status='Active'` |
| BR-10 | Chỉ Room `Vacant` được đăng tin hoặc tạo Lease mới; `Reserved` chặn cả hai. | Domain check + DB constraint |
| BR-11 | Tin tự đóng khi Room không còn `Vacant` hoặc Owner đóng thủ công; không thể mở lại tin cũ, phải tạo tin mới. | Event handler |
| BR-12 | Bản tin `Published` là snapshot bất biến; sửa nội dung tạo revision chờ duyệt; marketplace chỉ phục vụ snapshot đã duyệt. | Versioned listing |
| BR-13 | Mỗi tin tối đa một revision chờ duyệt; từ chối bắt buộc feedback; gửi lại tạo revision mới. | Unique partial index + validation |
| BR-14 | Miễn duyệt là cờ theo từng Owner; Admin có thể thu hồi; tin vẫn có thể bị báo cáo/hậu kiểm. | Admin console + audit |

### 6.3 Hợp đồng và dữ liệu nhạy cảm

| ID | Quy tắc | Cưỡng chế |
|---|---|---|
| BR-15 | Lease chỉ `Active` khi Owner và Renter đã ký; thiếu một bên thì không kích hoạt. | State machine |
| BR-16 | Nội dung Lease đã ký là bất biến; thay đổi qua phụ lục/phiên bản mới, có xác nhận. | Immutable snapshot + hash |
| BR-17 | Mỗi Lease có ít nhất một người đại diện; mọi người ở là người lớn phải có CCCD mặt trước/sau; người chưa thành niên ghi chú người giám hộ. | Validation |
| BR-18 | Xem CCCD của người khác cần quyền `document.cccd.view`; mọi lần xem có audit. Khi Lease kết thúc, CCCD archive; Staff mất quyền xem; Renter đại diện xem được ảnh của chính mình; Owner có quyền nhạy cảm và Platform Admin qua support access xem được ảnh archive. | Permission + lifecycle job |
| BR-19 | Chấm dứt Lease cần biên bản check-out `Locked` (hoặc quá 72 giờ với cờ `unconfirmedCheckout`) và hóa đơn cuối/hoàn cọc đã xử lý; nếu không thể thu/hoàn, Owner write-off khoản đó với lý do + audit (write-off không thay thế biên bản check-out); quá `endDate` Lease vẫn `EndingSoon` đến khi hoàn tất; Room chỉ về `Vacant` sau đó. | Termination service |
| BR-49 | Check-in lập sau khi Lease `Active`, trước bàn giao; bàn giao chỉ ghi nhận hoàn tất sau khi biên bản đã gửi Renter; `PendingRenter` không chặn Lease nhưng phải nhắc hàng ngày. | Lease/handover service |

### 6.4 Chỉ số, hóa đơn, thanh toán

| ID | Quy tắc | Cưỡng chế |
|---|---|---|
| BR-20 | Chỉ số mới ≥ chỉ số trước; ngoại lệ thay đồng hồ phải có cờ, ảnh, ghi chú, audit. | Domain validation |
| BR-21 | Hóa đơn chỉ sinh từ chỉ số `Confirmed`; nếu Renter im lặng 72 giờ, Owner được phát hành với cờ `unconfirmedReading` + audit; Renter vẫn được phản hồi sau. | Scheduler + flag |
| BR-22 | Hóa đơn đã phát hành là bất biến; sửa bằng void + phát hành lại; không xóa. | Immutable snapshot |
| BR-23 | Thanh toán cần minh chứng (số tiền, thời gian, ảnh/mã giao dịch); chỉ `payment.confirm` được chuyển `Paid`; từ chối phải có lý do. | State machine + permission |
| BR-24 | Không xử lý thanh toán online/ví/cổng ngân hàng; chỉ ghi nhận và xác nhận thủ công. | Scope guard |
| BR-25 | Tiền tệ VND, lưu số nguyên (đồng), không dấu thập phân; thành tiền = làm tròn nửa lên của `số lượng × đơn giá`; tổng = tổng các dòng. | Decimal policy |
| BR-26 | Ngày đến hạn mặc định ngày 5 tháng kế tiếp hoặc theo Lease; nhắc trước 3 ngày, đúng hạn, sau 3 ngày, sau 7 ngày; múi giờ `Asia/Ho_Chi_Minh`. | Scheduler |
| BR-27 | MVP không hỗ trợ thanh toán một phần; xác nhận phải bằng tổng hóa đơn, trừ khi Owner ghi đè có lý do + audit. | Validation |
| BR-28 | Hóa đơn `Paid` không được void; điều chỉnh phát sinh xử lý bằng hóa đơn điều chỉnh ở phiên bản sau. | State machine |

### 6.5 Biên bản, thông báo, ticket

| ID | Quy tắc | Cưỡng chế |
|---|---|---|
| BR-29 | Biên bản đã khóa là bất biến; thay đổi bằng phụ lục. | Immutable snapshot |
| BR-30 | Không có so sánh ảnh tự động hay màn hình so sánh trực tiếp; chỉ hiển thị ảnh theo khu vực để đối chiếu thủ công. | Product scope |
| BR-31 | Hoàn cọc chỉ là bản ghi; không xử lý chuyển tiền. | Scope guard |
| BR-32 | Thông báo giao dịch không được tắt; thông báo chung có thể tắt. | Preference validation |
| BR-33 | Thông báo theo Property chỉ gửi tới Renter đại diện có Lease `Active` trong Property đó; có preview + audit. | Recipient query |
| BR-34 | Ticket chỉ trong phạm vi Room/Property mà người dùng có quan hệ; không cross-tenant. | Authorization |
| BR-35 | Mọi thay đổi trạng thái ticket phải theo state machine; không nhảy trạng thái. | State machine |

### 6.6 Dữ liệu, file, kỹ thuật

| ID | Quy tắc | Cưỡng chế |
|---|---|---|
| BR-36 | Audit là append-only; không cập nhật/xóa. | DB permission/trigger |
| BR-37 | Không hard-delete Lease, hóa đơn, thanh toán, biên bản, audit; chỉ soft-delete và retention job theo chính sách. | Soft delete + job |
| BR-38 | Upload tối đa 10 MB/ảnh; kiểm tra magic bytes; re-encode; bucket private; signed URL 5 phút; object key chứa `tenantId`. | Upload service |
| BR-39 | Các thao tác sinh hóa đơn, xác nhận thanh toán, gửi broadcast, finalize upload phải idempotent. | Idempotency key |
| BR-40 | Lưu timestamp UTC; hiển thị theo `Asia/Ho_Chi_Minh`; kỳ hóa đơn theo tháng dương lịch. | Convention |
| BR-41 | Cập nhật Room/Lease/Invoice dùng optimistic concurrency; xung đột trả `409`. | Version column |
| BR-42 | Danh sách mặc định 20 phần tử, tối đa 100; không trả danh sách không giới hạn. | API policy |
| BR-43 | Marketplace chỉ trả tin `Published` với snapshot hiện hành; không trả draft/pending/rejected. | Public query |
| BR-44 | Owner chỉ được cấp quyền mà mình có; không cấp quyền nền tảng; không thay đổi quyền Owner chính. | Permission grant check |
| BR-45 | Thay đổi role/xóa Staff có hiệu lực ngay; phiên hiện tại bị thu hồi hoặc kiểm tra `membershipVersion`. | Auth middleware |
| BR-46 | Ràng buộc nghiệp vụ chỉ cưỡng chế ở write model (domain + PostgreSQL); read model MongoDB là projection, không phải nguồn sự thật và không được dùng để hợp thức hóa ghi. | Code review + test ràng buộc |
| BR-47 | Mỗi projection/read model document có thể rebuild từ write DB; projection handler idempotent; không sửa tay read model để "chữa" dữ liệu. | Rebuild job + review |
| BR-50 | Mọi domain GET/query API chỉ đọc MongoDB read model; query handler không query PostgreSQL. Ngoại lệ hạ tầng: auth/session, permission check, idempotency, support-access gate. Command handler chỉ ghi PostgreSQL + phát event qua CAP outbox. | Architecture test + code review |

---

## 7. State machine

### 7.1 Tài khoản Owner

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Active` | Hoạt động bình thường | `Suspended` |
| `Suspended` | Bị Admin khóa | `Active` (có lý do + audit) |

### 7.2 Room

| Trạng thái | Ý nghĩa | Chuyển tiếp hợp lệ |
|---|---|---|
| `Vacant` | Trống, có thể đăng tin/tạo Lease | `Reserved`, `Maintenance` |
| `Reserved` | Đã giữ chỗ/đặt cọc ngoài hệ thống | `Vacant` (hủy), `Occupied` |
| `Occupied` | Đang có Lease `Active` | `Ending` |
| `Ending` | Đang làm thủ tục trả phòng | `Vacant` |
| `Maintenance` | Sửa chữa/ngưng cho thuê | `Vacant` |

### 7.3 Listing và Listing Revision

**Listing**

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Draft` | Nháp, chưa gửi | `PendingReview`, `Closed` |
| `PendingReview` | Chờ duyệt lần đầu | `Published`, `Rejected` |
| `Published` | Đang hiển thị | `Closed` |
| `Rejected` | Bị từ chối | `Draft` (sửa/gửi lại), `Closed` |
| `Closed` | Đã đóng | — |

**Listing Revision**

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Draft` | Đang sửa | `PendingReview`, `Discarded` |
| `PendingReview` | Chờ duyệt bản sửa | `Approved`, `Rejected` |
| `Approved` | Trở thành snapshot hiện hành | — |
| `Rejected` | Bị từ chối, có feedback | `Draft` (sửa), `Discarded` |
| `Discarded` | Owner hủy bản sửa | — |

### 7.4 Lease

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Draft` | Owner đang soạn | `PendingRenterSignature`, `Cancelled` |
| `PendingRenterSignature` | Owner đã ký, chờ Renter | `Active`, `Cancelled` |
| `Active` | Đang hiệu lực | `EndingSoon`, `Terminated` |
| `EndingSoon` | Đang trong quá trình kết thúc (bắt đầu trước `endDate` 30 ngày) | `Terminated` (sau khi BR-19 hoàn tất; gia hạn tạo Lease mới) |
| `Terminated` | Đã kết thúc | — |
| `Cancelled` | Hủy trước khi hiệu lực | — |

> Quá `endDate` mà chưa hoàn tất check-out/hóa đơn cuối, Lease vẫn ở `EndingSoon`, không tự chuyển `Terminated` (D-19).

### 7.5 Condition Report

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Draft` | Đang lập | `PendingRenter` |
| `PendingRenter` | Chờ Renter xác nhận | `Locked`, `Disputed` |
| `Disputed` | Renter phản hồi | `Draft` (sửa), `Locked` |
| `Locked` | Đã chốt, bất biến | `Addendum` |

> `Locked` bình thường cần cả hai xác nhận; với check-out, Owner được lock sau 72 giờ theo FR-CND-11 và phải gắn cờ `unconfirmedCheckout` + audit.

### 7.6 Meter Reading

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Draft` | Đang nhập | `PendingRenter` |
| `PendingRenter` | Chờ Renter xác nhận | `Confirmed`, `Disputed` |
| `Disputed` | Renter phản hồi | `Draft` (sửa) |
| `Confirmed` | Đã xác nhận | `Invoiced` |
| `Invoiced` | Đã dùng để phát hành hóa đơn | — |

### 7.7 Invoice

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Issued` | Đã phát hành, chưa thanh toán | `PaymentSubmitted`, `Overdue`, `Void` |
| `PaymentSubmitted` | Có minh chứng, chờ Owner | `Paid`; `Issued`/`Overdue` (từ chối, quay về trạng thái trước khi gửi minh chứng) |
| `Paid` | Owner đã xác nhận | — |
| `Overdue` | Quá hạn | `PaymentSubmitted`, `Void` |
| `Void` | Hủy, thay thế bằng hóa đơn khác | — |

> Job quá hạn chỉ tác động hóa đơn `Issued`; `PaymentSubmitted` quá hạn giữ nguyên trạng thái và hiển thị cờ trễ (D-17).

### 7.8 Ticket

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `Open` | Mới tạo | `Acknowledged`, `Closed` |
| `Acknowledged` | Đã tiếp nhận | `InProgress`, `Closed` |
| `InProgress` | Đang xử lý | `Resolved` |
| `Resolved` | Đã xử lý | `Closed`, `Open` (reopen ≤ 7 ngày) |
| `Closed` | Đóng | — |

### 7.9 Viewing Request

| Trạng thái | Ý nghĩa | Chuyển tiếp |
|---|---|---|
| `New` | Mới gửi | `Contacted`, `Cancelled` |
| `Contacted` | Owner đã liên hệ | `Scheduled`, `Closed`, `Cancelled` |
| `Scheduled` | Đã hẹn xem | `Completed`, `Cancelled` |
| `Completed` | Đã xem | `Closed` |
| `Closed` | Kết thúc | — |
| `Cancelled` | Hủy | — |

---

## 8. Yêu cầu phi chức năng

### 8.1 Bảo mật và quyền riêng tư

| ID | Yêu cầu | Kiểm chứng |
|---|---|---|
| NFR-SEC-01 | TLS 1.2+ cho mọi kết nối; HSTS; security headers cơ bản. | Cấu hình + scan |
| NFR-SEC-02 | Mật khẩu hash Argon2id; tối thiểu 10 ký tự; rate limit 5 lần/phút/IP; khóa tạm sau 10 lần sai/15 phút. | Auth test |
| NFR-SEC-03 | Access token 15 phút; refresh token 30 ngày, rotation; thu hồi khi đổi mật khẩu/khóa tài khoản. | Auth test |
| NFR-SEC-04 | Mọi endpoint kiểm tra quyền phía server; deny-by-default; không tin UI. | Authorization test |
| NFR-SEC-05 | 100% endpoint tenant-scoped có test tiêu cực cross-tenant; CI fail nếu thiếu. | CI gate |
| NFR-SEC-06 | File private; signed URL hết hạn 5 phút; không URL công khai vĩnh viễn. | Storage test |
| NFR-SEC-07 | Kiểm tra loại file bằng magic bytes; giới hạn 10 MB; re-encode ảnh; chặn SVG/HTML. | Upload test |
| NFR-SEC-08 | Không log CCCD, ảnh biên lai, token, mật khẩu; không lưu các giá trị này trong audit `before`/`after`; che PII trong log. | Log review + audit review |
| NFR-SEC-09 | Mã hóa at-rest do nhà cung cấp managed; secret trong secret manager, không commit. | Config review |
| NFR-SEC-10 | Giảm thiểu OWASP Top 10; quét dependency trong CI. | Scan |
| NFR-PRV-01 | Có chính sách riêng tư/consent; yêu cầu xóa/sửa dữ liệu xử lý thủ công trong MVP. | Quy trình |
| NFR-PRV-02 | CCCD của người khác chỉ truy cập qua quyền nhạy cảm; Renter đại diện xem được ảnh của chính mình; mọi lần xem có audit. | Test + audit |

### 8.2 Hiệu năng và khả năng mở rộng

| ID | Yêu cầu | Kiểm chứng |
|---|---|---|
| NFR-PERF-01 | p95 API đọc ≤ 300 ms, ghi ≤ 800 ms (không tính upload) ở 200 người dùng đồng thời. | Load test |
| NFR-PERF-02 | Tìm kiếm marketplace p95 ≤ 500 ms với 10.000 tin. | Load test |
| NFR-PERF-03 | Danh sách ảnh dùng thumbnail + lazy load; không tải ảnh gốc trong list. | UI review |
| NFR-PERF-04 | Upload ảnh 5 MB trên mạng 1.5 Mbps hoàn tất ≤ 30 giây, có retry; không tạo bản ghi trùng. | Network throttle test |
| NFR-SCL-01 | Thiết kế cho 1.000 Owner, 20.000 Room, 100.000 hóa đơn/năm; API stateless, scale ngang; Hangfire worker chạy riêng, scale ngang với distributed lock. | Architecture review |

### 8.3 Độ tin cậy và vận hành

| ID | Yêu cầu | Kiểm chứng |
|---|---|---|
| NFR-AVL-01 | Availability mục tiêu 99.5%/tháng, không tính bảo trì có thông báo. | Monitoring |
| NFR-AVL-02 | Backup hằng ngày + PITR 7 ngày cho PostgreSQL; RPO ≤ 1 giờ, RTO ≤ 4 giờ; MongoDB read model rebuild từ PostgreSQL khi mất dữ liệu; diễn tập restore mỗi quý. | Restore drill |
| NFR-AVL-03 | Push thất bại không làm mất thông báo; inbox vẫn có bản ghi. | Failure test |
| NFR-OBS-01 | Log có cấu trúc, `requestId`, `tenantId`, `userId` (không PII); trace lỗi xuyên service. | Log review |
| NFR-OBS-02 | Error tracking + metric + alert cho 5xx, job lag, push failure, upload failure. | Dashboard |
| NFR-OBS-03 | Audit tách khỏi application log; không phụ thuộc log retention. | Architecture review |
| NFR-OBS-04 | Audit mọi thao tác của actor đã xác thực ghi bất đồng bộ qua CAP outbox, không chặn response; activity log đọc từ read model; retention theo mục 11. | Load test + architecture review |

### 8.4 Web responsive và mạng yếu

| ID | Yêu cầu | Kiểm chứng |
|---|---|---|
| NFR-WEB-01 | Một web app responsive cho mọi actor; hỗ trợ Chrome/Edge/Safari/Firefox 2 phiên bản gần nhất, viewport 360 px → 1920 px, không cuộn ngang ở 360 px. | Browser matrix + UI review |
| NFR-WEB-02 | Ảnh nén client (cạnh dài ≤ 1920 px, chất lượng ~85%); upload có progress, retry, resume/chunk khi có thể. | Manual test |
| NFR-WEB-03 | Không offline mode; cho phép cache đọc tạm nhưng không ghi offline; không yêu cầu service worker cache toàn app. | Scope review |
| NFR-WEB-04 | Chọn ảnh từ thiết bị qua `<input type=file>` (kèm `capture` trên mobile browser); xử lý từ chối quyền camera/thư viện. | Manual test |
| NFR-WEB-05 | Web Push qua FCM (service worker); nếu người dùng từ chối quyền, inbox vẫn hoạt động. | Manual test |

### 8.5 Dữ liệu, ngôn ngữ, UX

| ID | Yêu cầu | Kiểm chứng |
|---|---|---|
| NFR-DAT-01 | Lưu UTC; hiển thị `Asia/Ho_Chi_Minh`; định dạng ngày `dd/MM/yyyy`. | Test |
| NFR-DAT-02 | VND, số nguyên; không dùng floating point cho tiền. | Code review + test |
| NFR-DAT-03 | Retention theo mục 11; job xóa/archive có audit. | Job test |
| NFR-DAT-04 | Soft-delete cho dữ liệu nghiệp vụ; không hard-delete ngoài retention. | DB review |
| NFR-DAT-05 | Read model MongoDB là projection rebuild được từ PostgreSQL; lag p95 ≤ 2 giây; rebuild toàn bộ ≤ 60 phút với dữ liệu mục tiêu NFR-SCL-01. | Metric + rebuild drill |
| NFR-DAT-06 | Tiền lưu số nguyên 64-bit (đồng) ở write DB và read model; không dùng `double`. | Code review + test |
| NFR-DAT-07 | 100% domain GET/query API đọc MongoDB read model; query handler không query PostgreSQL (trừ auth/session, permission, idempotency); architecture test trong CI. | Architecture test |
| NFR-UX-01 | Tiếng Việt, responsive-first; luồng chính hoàn tất được trên viewport 360 px (mobile browser) và desktop 1280 px. | UI review |
| NFR-UX-02 | Touch target ≥ 44 px; label rõ; hỗ trợ screen reader cho luồng chính; tương phản đạt WCAG AA. | Accessibility check |
| NFR-UX-03 | Lỗi hiển thị hành động khắc phục; không lộ stack trace. | Manual test |
| NFR-COMP-01 | Không cung cấp dịch vụ thanh toán/tài chính; không lưu thông tin thẻ/tài khoản ngân hàng. | Scope review |

---

## 9. Mô hình dữ liệu mức nghiệp vụ

### 9.1 Thực thể chính

| Thực thể | Phạm vi | Trường chính | Ghi chú |
|---|---|---|---|
| `User` | Toàn nền tảng | id, email, phone, passwordHash, status | Email/phone unique |
| `PlatformAdmin` | Toàn nền tảng | userId, level | Không thuộc tenant |
| `OwnerTenant` | Toàn nền tảng | id, ownerUserId, name, status | `TenantId` |
| `StaffMembership` | Tenant | tenantId, userId, status | Unique userId → một Owner |
| `Role` | Tenant | tenantId, name, isSystem | Role mẫu + custom |
| `Permission` | Toàn nền tảng | code, group, isSensitive | Danh mục cố định |
| `RolePermission` | Tenant | roleId, permissionCode | Grant |
| `RoleAssignment` | Tenant | membershipId, roleId, propertyScope | Có thể giới hạn Property |
| `Property` | Tenant | tenantId, name, address, rules | |
| `Room` | Tenant | tenantId, propertyId, code, area, rent, deposit, status | Unique (propertyId, code) |
| `Tariff` | Tenant | tenantId, propertyId/roomId, type, method, price, effectiveFrom/To | Snapshot khi phát hành hóa đơn |
| `Listing` | Tenant | tenantId, roomId, status, currentRevisionId | Một tin active/Room |
| `ListingRevision` | Tenant | listingId, versionNo, title, description, price, amenities, status, feedback | Snapshot bất biến khi duyệt |
| `ListingPhoto` | Tenant | revisionId, objectKey, order, isCover | Private |
| `ViewingRequest` | Tenant | listingId, seekerName, phone, message, preferredAt, status | Seeker không cần tài khoản |
| `Lease` | Tenant | tenantId, roomId, representativeUserId, startDate, endDate, rent, deposit, status, version | Một Active/Room |
| `LeaseVersion` | Tenant | leaseId, versionNo, contentHash, snapshot | Bất biến |
| `Occupant` | Tenant | leaseId, fullName, dob, idNumber, phone, role | Người đại diện + ở cùng; chỉ hồ sơ, không có tài khoản (D-16) |
| `OccupantDocument` | Tenant | occupantId, type, objectKey, status | CCCD, nhạy cảm |
| `LeaseSignature` | Tenant | leaseVersionId, userId, role, signedAt, ip, device, hash | Xác nhận trên web |
| `ConditionReport` | Tenant | leaseId, type (in/out), status, lockedAt, unconfirmedCheckout | Cờ khi lock check-out sau timeout |
| `ConditionArea` | Tenant | reportId, name, note, condition | |
| `ConditionPhoto` | Tenant | areaId, objectKey, capturedAt, uploadedBy | Immutable sau khóa |
| `MeterReading` | Tenant | roomId, utility, period, previous, current, photoKey, status, confirmedAt | Unique (room, utility, period) |
| `Invoice` | Tenant | leaseId, period, dueDate, total, status, issuedAt, voidReason | Immutable sau phát hành; cờ `unconfirmedReading` |
| `InvoiceLine` | Tenant | invoiceId, type, description, quantity, unitPrice, amount | Snapshot |
| `PaymentRecord` | Tenant | invoiceId, amount, paidAt, proofKey, reference, status, confirmedBy | Không xử lý tiền |
| `Ticket` | Tenant | roomId, createdBy, category, title, description, priority, status | |
| `TicketMessage` | Tenant | ticketId, authorId, body, isInternal | Internal note |
| `Notification` | Toàn nền tảng/tenant | recipientId, type, entityType, entityId, title, body, readAt | Inbox |
| `DeviceToken` | Toàn nền tảng | userId, platform, token | Web Push subscription |
| `AuditEvent` | Toàn nền tảng/tenant | actor, tenantId, action, entity, before/after, ip, requestId, reason | Append-only; before/after đã che PII (D-18) |
| `FileObject` | Toàn nền tảng/tenant | tenantId, key, contentType, size, checksum, owner | Private bucket |
| `IdempotencyKey` | Toàn nền tảng | key, userId, endpoint, responseHash, expiresAt | Chống trùng |

### 9.2 Ràng buộc và chỉ mục

> Các ràng buộc dưới đây cưỡng chế ở **PostgreSQL (write DB)**. MongoDB chỉ là read model: không thay thế ràng buộc và có thể rebuild.

- `Lease`: partial unique index trên `roomId` với `status = 'Active'`.
- `Room`: unique `(tenantId, propertyId, code)`.
- `ListingRevision`: unique `(listingId, versionNo)`; partial unique một revision `PendingReview`/`Draft` hoạt động cho mỗi Listing.
- `MeterReading`: unique `(roomId, utility, period)`.
- `Invoice`: partial unique `(leaseId, period)` where `status <> 'Void'` (một hóa đơn hiện hành mỗi kỳ); hóa đơn thay thế có `replacesInvoiceId`, chỉ tạo sau khi hóa đơn cũ đã `Void`.
- `StaffMembership`: unique `userId` (một Staff một Owner) — hoặc unique `(userId)` với trạng thái `Active`.
- Mọi bảng tenant-scoped có index `(tenantId, ...)` cho truy vấn chính.
- `AuditEvent`: index `(tenantId, occurredAt)`, `(entityType, entityId)`.
- `Notification`: index `(recipientId, readAt, createdAt)`.

### 9.3 Phân loại dữ liệu

| Mức | Dữ liệu | Biện pháp |
|---|---|---|
| **Public** | Tin đăng đã duyệt, ảnh phòng đã duyệt | Được phục vụ cho Seeker |
| **Internal** | Property/Room, hợp đồng, hóa đơn, ticket | Tenant isolation + auth |
| **Sensitive** | CCCD, số điện thoại, ảnh biên lai, địa chỉ chính xác | Quyền nhạy cảm, audit, signed URL, che log |
| **Secret** | Mật khẩu hash, refresh token, khóa ký, secret hạ tầng | Secret manager, không log |

### 9.4 Cách ly tenant

- `TenantId` lấy từ membership trong token; không nhận từ query/body.
- Mọi domain GET/query handler đọc MongoDB; không query PostgreSQL trong handler. Auth/session, permission, idempotency là ngoại lệ hạ tầng.
- Write model: global query filter (EF Core) + kiểm tra service layer.
- Read model MongoDB: mọi document tenant-scoped có `tenantId`; read repository bắt buộc filter. Projection marketplace công khai là ngoại lệ duy nhất và chỉ chứa snapshot `Published`.
- Projection đi qua **CAP outbox**; handler idempotent; read model sai lệch thì rebuild, không sửa tay.
- Test cross-tenant áp dụng cho cả read side (endpoint trả dữ liệu từ MongoDB).
- Truy vấn công khai (marketplace) dùng projection riêng, chỉ đọc bản `Published`.
- Renter đại diện dùng `Lease.representativeUserId` để truy vấn xuyên tenant; không dùng `TenantId` của Renter.
- File object key: `tenant/{tenantId}/{entity}/{id}/{fileId}`; signed URL kiểm tra quyền trước khi ký.
- Platform Admin support access dùng token ngắn hạn, ghi audit, không bypass authorization thường.

---

## 10. Danh mục quyền

| Mã | Nhóm | Mô tả | Nhạy cảm |
|---|---|---|---|
| `tenant.settings.read` | Tenant | Xem cấu hình tenant | Không |
| `tenant.settings.write` | Tenant | Sửa cấu hình tenant | Không |
| `staff.manage` | Tenant | Mời/xóa/khóa Staff, gán role | Có |
| `property.read` | Property | Xem Property | Không |
| `property.write` | Property | Tạo/sửa/lưu trữ Property | Không |
| `room.read` | Room | Xem Room | Không |
| `room.write` | Room | Tạo/sửa/lưu trữ Room | Không |
| `tariff.read` | Tài chính | Xem bảng giá | Không |
| `tariff.write` | Tài chính | Sửa bảng giá | Có |
| `listing.read` | Tin đăng | Xem tin của tenant | Không |
| `listing.write` | Tin đăng | Tạo/sửa/gửi tin | Không |
| `lease.read` | Hợp đồng | Xem hợp đồng | Không |
| `lease.create` | Hợp đồng | Tạo hợp đồng | Không |
| `lease.terminate` | Hợp đồng | Chấm dứt hợp đồng | Có |
| `document.cccd.view` | Tài liệu | Xem ảnh CCCD | Có |
| `condition.read` | Biên bản | Xem biên bản | Không |
| `condition.write` | Biên bản | Tạo/sửa biên bản | Không |
| `meter.read` | Điện nước | Xem chỉ số | Không |
| `meter.write` | Điện nước | Nhập/sửa chỉ số | Không |
| `invoice.read` | Hóa đơn | Xem hóa đơn | Không |
| `invoice.create` | Hóa đơn | Phát hành/void hóa đơn | Không |
| `payment.confirm` | Hóa đơn | Xác nhận/từ chối thanh toán | Có |
| `ticket.read` | Ticket | Xem ticket | Không |
| `ticket.update` | Ticket | Cập nhật/trả lời ticket | Không |
| `notification.send` | Thông báo | Gửi thông báo Property | Không |
| `audit.read` | Audit | Xem audit tenant | Không |
| `platform.owner.manage` | Platform | Khóa/mở Owner | Có |
| `platform.listing.moderate` | Platform | Duyệt/từ chối tin | Có |
| `platform.support.access` | Platform | Support access có lý do | Có |

**Quy tắc cấp quyền**

- Quyền nhạy cảm phải được bật riêng, hiển thị cảnh báo, và ghi audit khi cấp/thu hồi.
- `manager` mặc định không có `document.cccd.view`, `payment.confirm`, `lease.terminate`, `staff.manage`, `tariff.write`.
- Chỉ Owner chính có `staff.manage` và `tenant.settings.write`; không cấp hai quyền này cho Staff và không thể xóa quyền của Owner chính (BR-48).
- Platform permission không thể gán cho tenant role.

---

## 11. Audit và lưu trữ

### 11.1 Sự kiện audit tối thiểu

> Audit ghi **mọi thao tác của actor đã xác thực** (Owner/Staff/Renter/Platform Admin) và các sự kiện quan trọng dưới đây; Owner xem được audit của chính mình và activity log của Staff. Audit tách application log, append-only, không chứa PII (D-18, D-21).

- Mọi thao tác của actor đã xác thực: xem/đọc dữ liệu, tạo/sửa/xóa, tải file, xuất PDF; kèm actor, tenant, thời gian, entity, kết quả.
- Đăng nhập thành công/thất bại, đổi mật khẩu, thu hồi phiên.
- Tạo/sửa/lưu trữ Property, Room, bảng giá.
- Tạo/sửa/gửi/duyệt/từ chối/đóng tin.
- Tạo/sửa/ký/chấm dứt Lease; xem CCCD; archive CCCD.
- Tạo/khóa biên bản; ghi nhận khấu trừ/hoàn cọc.
- Nhập/sửa/xác nhận/phản hồi chỉ số.
- Phát hành/void hóa đơn; gửi/xác nhận/từ chối thanh toán.
- Gửi thông báo Property; thay đổi ticket.
- Mời/xóa/khóa Staff; thay đổi role/permission.
- Platform Admin khóa/mở Owner; support access; duyệt/từ chối tin.

### 11.2 Chính sách lưu trữ đề xuất

| Dữ liệu | Thời hạn | Ghi chú |
|---|---|---|
| Hợp đồng, phụ lục, chữ ký | 10 năm sau khi kết thúc | Đề xuất, cần xác nhận pháp lý |
| Hóa đơn, thanh toán, audit | 10 năm | Đề xuất |
| CCCD | 24 tháng sau khi Lease kết thúc, sau đó xóa cứng | Đề xuất, cần xác nhận |
| Ảnh biên bản | 24 tháng sau khi Lease kết thúc | Đề xuất |
| Tin đăng + ảnh | 12 tháng sau khi đóng | |
| Ticket | 24 tháng sau khi đóng | |
| Notification | 12 tháng | |
| Application log | 90 ngày | |
| Backup | 30 ngày | PITR 7 ngày |

> Các thời hạn trên là **đề xuất kỹ thuật**, chưa phải tư vấn pháp lý. Chốt tại `OD-02`.

---

## 12. Phạm vi MVP và lộ trình

### 12.1 Must / Should / Won't

| Must (MVP) | Should (nếu kịp) | Won't (v2+) |
|---|---|---|
| Auth, tenant, RBAC, audit | Tạo nhanh nhiều phòng | Chữ ký số pháp lý |
| Property/Room/Tariff | Báo cáo vi phạm tin | Đánh giá/review |
| Listing + moderation + revision | Xuất CSV audit | Báo cáo doanh thu/dashboard nâng cao |
| Marketplace search + viewing request | Màn hình quản lý thiết bị | Đa ngôn ngữ |
| Lease + occupant + CCCD + sign | Thông báo email giao dịch | Chat nhóm/realtime |
| Condition report + photo | | So sánh ảnh tự động/AI |
| Meter + invoice + payment proof/confirm | | Thanh toán online/ví |
| Push + inbox + Property broadcast | | Billing/phí nền tảng |
| Ticket | | Offline mode |
| Admin console (owner, moderation) | | SEO/quảng cáo trả phí cho marketplace công khai |
| Audit viewer | | App native iOS/Android |

### 12.2 Epic

| Epic | Kết quả | Phụ thuộc |
|---|---|---|
| **E0 — Nền tảng kỹ thuật** | Repo, CI, môi trường, PostgreSQL + MongoDB, storage, Hangfire, auth skeleton, CQRS + CAP outbox + projection skeleton, test harness, ADR chi tiết tech stack (D-14) | — |
| **E1 — Danh tính, tenant, RBAC, audit** | Owner/Staff/Renter, tenant auto, role, audit, isolation tests | E0 |
| **E2 — Property/Room/Tariff** | CRUD, trạng thái phòng, bảng giá | E1 |
| **E3 — Listing/Marketplace/Moderation** | Tin, ảnh, duyệt, revision, tìm kiếm, viewing request, admin console | E2 |
| **E4 — Lease/Signing/Occupants** | Hợp đồng, lời mời, người ở, CCCD, ký, PDF, archive | E2, E3 |
| **E5 — Condition Report** | Check-in/out, ảnh, xác nhận, khóa, khấu trừ, hoàn cọc | E4 |
| **E6 — Meter/Invoice/Payment** | Chỉ số, xác nhận, hóa đơn, minh chứng, xác nhận thanh toán, nhắc hạn | E4 |
| **E7 — Notification/Ticket/Audit UI** | Push/inbox, broadcast, ticket, audit viewer | E1–E6 |
| **E8 — Hardening/Pilot** | Load/security test, backup/restore, UAT, runbook, pilot | E0–E7 |

### 12.3 Lộ trình sprint (một người, 2 tuần/sprint)

| Sprint | Thời lượng | Mục tiêu | Deliverable | Exit criteria |
|---|---|---|---|---|
| **S0** | 1 tuần | Dựng nền tảng theo stack đã chốt | ADR chi tiết (layering DDD, command/query, CAP outbox/projection, Hangfire), repo, CI, dev/staging, PostgreSQL + MongoDB, storage, push spike, tenant-isolation test harness | Deploy "hello" + CI xanh + ADR được duyệt |
| **S1** | 2 tuần | E1 | Auth, tenant auto, Staff invite, role/permission, audit, session | Owner đăng ký/đăng nhập; Staff chỉ một Owner; test cross-tenant pass |
| **S2** | 2 tuần | E2 | Property/Room/Tariff, trạng thái phòng, web app shell responsive | CRUD đầy đủ; Room state machine; test quyền |
| **S3** | 2 tuần | E3 | Listing, upload ảnh, moderation, revision, marketplace search, viewing request | Seeker tìm thấy tin đã duyệt; sửa tin không đổi bản công khai; admin duyệt/từ chối |
| **S4** | 2 tuần | E4 | Lease, invite, occupants, CCCD, sign, PDF, archive | Hai bên ký → Active; PDF hash khớp; CCCD archive khi kết thúc |
| **S5** | 2 tuần | E5 | Check-in/out, ảnh theo khu vực, xác nhận/khóa, khấu trừ, hoàn cọc | Biên bản khóa bất biến; ảnh có timestamp; PDF xuất được |
| **S6** | 2 tuần | E6 | Meter, renter confirm, invoice, payment proof, owner confirm, reminders | Vòng hóa đơn E2E; trạng thái đúng; không có thanh toán online |
| **S7** | 2 tuần | E7 | Push/inbox, Property broadcast, ticket, audit viewer | Broadcast đúng đối tượng; ticket flow; audit thao tác nhạy cảm |
| **S8** | 1–2 tuần | E8 | Load/security test, backup/restore, UAT, runbook, pilot | Đạt SC-03/05/06; pilot 5–10 Owner |

**Tổng**: khoảng 17–18 tuần, chưa gồm buffer 20%.

### 12.4 Cách chia task

- Mỗi task là **lát cắt dọc** nhỏ nhất có thể demo: schema → domain → API → UI → test → audit (nếu có).
- Task ≤ 1 ngày; nếu > 2 ngày phải tách.
- Mỗi task phải tham chiếu `FR-*`/`AC-*`, có authorization + tenant isolation + audit cho mọi thao tác của actor đã xác thực.
- Không có task "làm sau"; không commit code chết, không mock trong nhánh chính.
- Thứ tự trong sprint: write schema/migration → domain/state machine → command handler → CAP outbox → projection read model → query API → UI → E2E → demo.
- Mỗi sprint bắt đầu bằng cập nhật spec/change proposal và kết thúc bằng demo + retrospective.
- WIP limit = 1; buffer 20% cho bug/UAT.

### 12.5 Definition of Done

Một task chỉ `Done` khi:

- [ ] AC tương ứng pass.
- [ ] Có test tự động cho luồng chính + ít nhất một edge case.
- [ ] Có test cross-tenant/authorization nếu endpoint tenant-scoped.
- [ ] Migration PostgreSQL chạy lại/rollback được; không phá dữ liệu cũ.
- [ ] Projection MongoDB cập nhật từ write model qua CAP outbox; có lệnh rebuild và test projection.
- [ ] Hangfire job (nếu có) idempotent, retry an toàn, không giữ transaction dài.
- [ ] Domain GET/query handler chỉ đọc MongoDB; architecture test xác nhận không có query PostgreSQL trong handler.
- [ ] Audit event được ghi cho mọi thao tác của actor đã xác thực và thao tác nhạy cảm.
- [ ] API trả lỗi đúng mã, không lộ stack trace/PII.
- [ ] UI xử lý loading/empty/error/retry.
- [ ] UI responsive: không cuộn ngang ở 360 px, dùng được ở desktop 1280 px.
- [ ] Tài liệu/ADR cập nhật nếu thay đổi quyết định.
- [ ] Demo được trên staging.

### 12.6 Release gate trước pilot

- Không còn lỗi P0/P1.
- Bộ test cách ly tenant xanh 100%.
- Bộ test E2E vòng thuê xanh.
- Load test đạt NFR-PERF-01/02.
- Backup/restore diễn tập thành công.
- Runbook: deploy, rollback, backup, sự cố push, sự cố upload.
- Chính sách quyền riêng tư/consent và hướng dẫn xử lý dữ liệu nhạy cảm.

---

## 13. Tiêu chí chấp nhận

### 13.1 Tenant và phân quyền

| ID | Given / When / Then |
|---|---|
| AC-TEN-01 | Given Owner A đã đăng nhập, When gọi API đọc Property của Owner B, Then trả `404`, không có dữ liệu B, có audit từ chối. |
| AC-TEN-02 | Given endpoint danh sách tenant-scoped, When gọi với token của tenant khác, Then chỉ trả dữ liệu tenant hiện tại ở cả write model lẫn read model MongoDB; test âm tính tồn tại trong CI. |
| AC-RBAC-01 | Given Staff không có `document.cccd.view`, When mở ảnh CCCD, Then `403`, không trả URL, có audit. |
| AC-RBAC-02 | Given Staff được giao Property P1, When thao tác trên Property P2 cùng tenant, Then `403`. |
| AC-RBAC-03 | Given Owner thu hồi role của Staff, When Staff dùng token cũ, Then bị từ chối ngay. |
| AC-RBAC-04 | Given Platform Admin mở support access, When chưa nhập lý do hoặc quá 24 giờ, Then bị chặn; khi truy cập, Then có audit và mặc định chỉ đọc. |
| AC-RBAC-05 | Given Owner cấp `tenant.settings.write` hoặc `staff.manage` cho Staff, When lưu role, Then bị chặn và có audit từ chối. |
| AC-SUS-01 | Given Owner bị `Suspended`, When tạo tin/Lease mới hoặc đổi giá, Then bị chặn; When phát hành hóa đơn, xác nhận thanh toán hoặc xử lý check-out cho Lease hiện hữu, Then thành công; Renter vẫn xem hợp đồng/hóa đơn và gửi minh chứng. |

### 13.2 Tin đăng và marketplace

| ID | Given / When / Then |
|---|---|
| AC-LST-01 | Given tin `Published`, When Owner sửa giá, Then marketplace vẫn hiển thị giá cũ; revision mới ở `PendingReview`; admin duyệt xong mới đổi. |
| AC-LST-02 | Given tin bị từ chối, When Owner mở tin, Then thấy feedback bắt buộc; gửi lại tạo revision mới. |
| AC-LST-03 | Given Room chuyển `Occupied`, When job chạy, Then tin `Closed` và không còn trong kết quả tìm kiếm. |
| AC-LST-04 | Given Seeker không đăng nhập, When tìm kiếm, Then chỉ thấy tin `Published` hiện hành, không thấy draft/pending/rejected. |
| AC-LST-05 | Given Owner bật ẩn địa chỉ, When Seeker xem tin, Then không thấy số nhà; sau khi Owner chấp nhận yêu cầu xem, Seeker thấy địa chỉ đầy đủ. |

### 13.3 Hợp đồng và CCCD

| ID | Given / When / Then |
|---|---|
| AC-LSE-01 | Given Room đã có Lease `Active`, When tạo Lease mới, Then bị từ chối ở cả domain và DB constraint. |
| AC-LSE-02 | Given Owner đã ký, When Renter chưa ký, Then Lease chưa `Active`; sau khi Renter ký, Then `Active`, Room `Occupied`, tin đóng. |
| AC-LSE-03 | Given Lease đã ký, When sửa nội dung, Then bị chặn; tạo phụ lục/phiên bản mới thành công. |
| AC-LSE-04 | Given Lease kết thúc, When job archive chạy, Then CCCD không còn trong UI thường/Staff; Owner có quyền xem archive; mọi lần xem có audit. |
| AC-LSE-05 | Given PDF hợp đồng đã tạo, When tải lại, Then hash khớp; nếu nội dung bị sửa, kiểm tra hash thất bại. |
| AC-LSE-06 | Given Lease quá `endDate` nhưng chưa check-out/hóa đơn cuối, When job chạy, Then Lease vẫn `EndingSoon`, Room vẫn `Ending`; chỉ `Terminated` sau khi BR-19 hoàn tất. |

### 13.4 Biên bản

| ID | Given / When / Then |
|---|---|
| AC-CND-01 | Given biên bản check-in đã khóa, When sửa ảnh/ghi chú, Then bị chặn; tạo phụ lục thành công. |
| AC-CND-02 | Given check-out, When mở khu vực, Then thấy ảnh check-in và check-out cùng khu vực; không có màn hình so sánh trực tiếp. |
| AC-CND-03 | Given Renter phản hồi biên bản, When Owner sửa và gửi lại, Then biên bản quay về `PendingRenter`, không bị khóa. |
| AC-CND-04 | Given hư hỏng có khấu trừ, When chốt check-out, Then số tiền cọc/khấu trừ/hoàn được ghi nhận và xuất PDF. |
| AC-CND-05 | Given Lease `Active`, When Owner chưa gửi biên bản check-in, Then không ghi nhận bàn giao; When đã gửi, Then bàn giao được ghi nhận dù biên bản `PendingRenter` và hệ thống nhắc Renter hàng ngày. |
| AC-CND-06 | Given Renter không phản hồi biên bản check-out trong 72 giờ, When Owner chốt, Then biên bản `Locked` với cờ `unconfirmedCheckout` + audit; trước 72 giờ, Then bị chặn. |

### 13.5 Điện nước, hóa đơn, thanh toán

| ID | Given / When / Then |
|---|---|
| AC-MTR-01 | Given chỉ số trước 100, When nhập 90, Then bị từ chối; khi bật `meterReplaced` + ghi chú + ảnh, Then chấp nhận và audit. |
| AC-MTR-02 | Given Renter xác nhận chỉ số, When phát hành hóa đơn, Then hóa đơn sinh đúng dòng/đơn giá snapshot, tổng đúng. |
| AC-MTR-03 | Given Renter không phản hồi 72 giờ, When Owner phát hành, Then hóa đơn có cờ `unconfirmedReading`, audit, Renter vẫn phản hồi được. |
| AC-INV-01 | Given hóa đơn `Issued`, When Renter tải minh chứng, Then `PaymentSubmitted`; When Owner từ chối, Then về `Issued` kèm lý do. |
| AC-INV-02 | Given hóa đơn `PaymentSubmitted`, When người không có `payment.confirm` xác nhận, Then `403`; Owner xác nhận, Then `Paid` + audit. |
| AC-INV-03 | Given hóa đơn `Paid`, When void, Then bị chặn; hóa đơn `Issued`/`Overdue` void được kèm lý do. |
| AC-INV-04 | Given hóa đơn `Issued` quá hạn, When job chạy, Then chuyển `Overdue`; các mốc nhắc −3/0/+3/+7 ngày được gửi đúng lịch. |
| AC-INV-05 | Given hóa đơn của Lease A, When Renter B mở, Then `404`; Renter A mở được. |
| AC-INV-06 | Given hóa đơn `PaymentSubmitted` quá hạn, When job chạy, Then giữ `PaymentSubmitted` và gắn cờ trễ; Given hóa đơn `Issued` quá hạn, When job chạy, Then `Overdue`. |

### 13.6 Thông báo, ticket, audit

| ID | Given / When / Then |
|---|---|
| AC-NTF-01 | Given Property có 3 Renter đại diện active và 1 Renter đại diện đã kết thúc, When broadcast, Then chỉ 3 người active nhận; có audit. |
| AC-NTF-02 | Given push thất bại, When mở web, Then thông báo vẫn có trong inbox. |
| AC-TKT-01 | Given Renter tạo ticket cho Room đang thuê, When Owner mở, Then thấy ticket; Renter khác không thấy. |
| AC-TKT-02 | Given ticket `Resolved`, When Renter mở lại trong 7 ngày, Then `Open`; quá 7 ngày, Then bị chặn. |
| AC-ADT-01 | Given xem CCCD/xác nhận thanh toán/đổi quyền, When thao tác, Then có audit với actor, tenant, entity, timestamp, IP/requestId. |
| AC-ADT-02 | Given audit đã ghi, When gọi API sửa/xóa, Then không tồn tại hoặc `405`; DB từ chối update/delete. |
| AC-ADT-03 | Given xem CCCD hoặc xác nhận thanh toán, When audit được ghi, Then `before`/`after` không chứa số CCCD, ảnh, token; giá trị nhạy cảm được che. |
| AC-ADT-04 | Given Owner/Staff/Renter/Admin xem/sửa/tải file/xuất PDF, When thao tác, Then audit ghi actor, tenant, action, entity, timestamp, kết quả; Owner lọc được activity log của chính mình và của Staff. |

### 13.7 Phi chức năng

| ID | Given / When / Then |
|---|---|
| AC-PERF-01 | Given 200 người dùng đồng thời, When chạy load test, Then p95 đọc ≤ 300 ms, ghi ≤ 800 ms. |
| AC-UPL-01 | Given mạng 1.5 Mbps, When upload ảnh 5 MB, Then hoàn tất ≤ 30 giây, có retry, không tạo bản ghi trùng. |
| AC-SEC-01 | Given 10 lần đăng nhập sai trong 15 phút, When thử tiếp, Then bị khóa tạm; không lộ tài khoản tồn tại. |
| AC-SEC-02 | Given file `.svg`/HTML đổi đuôi `.jpg`, When upload, Then bị từ chối do magic bytes. |
| AC-REST-01 | Given backup trước sự cố, When restore vào môi trường sạch, Then dữ liệu mẫu khôi phục trong RTO ≤ 4 giờ. |
| AC-ARCH-01 | Given một domain GET endpoint, When gọi, Then dữ liệu trả về từ MongoDB read model; architecture test không phát hiện query PostgreSQL trong query handler (trừ auth/permission/idempotency). |
| AC-UX-01 | Given viewport 360 px và desktop 1280 px, When mở các luồng chính, Then không cuộn ngang và không mất chức năng; Web Push bị từ chối quyền thì inbox vẫn hoạt động. |

---

## 14. Rủi ro và biện pháp

| ID | Rủi ro | Tác động | Xác suất | Biện pháp |
|---|---|---|---|---|
| R-01 | Quên lọc `TenantId` gây lộ dữ liệu | Rất cao | Trung bình | Global filter + test cross-tenant bắt buộc + review |
| R-02 | Lộ CCCD/ảnh biên lai | Rất cao | Trung bình | Quyền nhạy cảm, signed URL ngắn, audit, không log PII |
| R-03 | Scope creep sang thanh toán/chat | Cao | Cao | Ghi rõ ngoài phạm vi; mọi yêu cầu mới phải thành change riêng |
| R-04 | Một người làm quá tải | Cao | Cao | Sprint 2 tuần, task ≤ 1 ngày, buffer 20%, cắt `Should` trước |
| R-05 | Renter không chịu dùng web | Cao | Trung bình | Giả định MVP; khảo sát pilot; fallback giấy xử lý ngoài hệ thống |
| R-06 | Renter không xác nhận chỉ số | Trung bình | Cao | Timeout 72 giờ + cờ `unconfirmedReading` + audit |
| R-07 | Duyệt tin chậm | Trung bình | Trung bình | Hàng đợi + SLA 24h + cờ miễn duyệt cho Owner tin cậy |
| R-08 | Push không đến | Trung bình | Cao | Inbox là nguồn sự thật; retry; hiển thị trạng thái |
| R-09 | Ảnh tốn dung lượng/chi phí | Trung bình | Trung bình | Nén client, thumbnail, retention, lifecycle storage |
| R-10 | Hợp đồng không có giá trị pháp lý | Trung bình | Cao | Ghi rõ mức xác nhận; tư vấn pháp lý trước pilot |
| R-11 | Lưu CCCD quá lâu | Cao | Trung bình | Retention 24 tháng + job xóa + audit |
| R-12 | Tranh chấp dữ liệu do sửa hóa đơn/biên bản | Cao | Trung bình | Immutable + version + audit + void/reissue |

---

## 15. Quyết định còn mở

| ID | Quyết định | Mặc định trong BRD | Cần chốt trước | Ảnh hưởng |
|---|---|---|---|---|
| OD-01 | Tech stack backend/web/DB/hosting | **Đã chốt (D-14, mục 1.7)**: ASP.NET Core + DDD/CQRS, PostgreSQL write + MongoDB read, Hangfire, Next.js/Tailwind CSS/GSAP (một web app responsive) | Đã chốt 2026-11-23 | Toàn bộ kiến trúc |
| OD-02 | Thời hạn lưu CCCD/hợp đồng/hóa đơn | Đề xuất ở mục 11 | Sprint 4 | Storage, compliance, job xóa |
| OD-03 | Timeout xác nhận chỉ số 72 giờ | 72 giờ | Sprint 6 | Luồng hóa đơn |
| OD-04 | Owner tự kích hoạt hay Admin duyệt | Tự kích hoạt | Sprint 1 | Onboarding, kiểm soát |
| OD-05 | Ai xem CCCD archive | Owner có quyền + Admin support access | Sprint 4 | Quyền riêng tư |
| OD-06 | Staff có được cấp `payment.confirm` | Có, nhưng phải bật riêng | Sprint 6 | Kiểm soát tiền |
| OD-07 | Ẩn địa chỉ chính xác mặc định | Bật ẩn | Sprint 3 | Marketplace, an toàn |
| OD-08 | Cọc: chỉ ghi nhận hay có minh chứng | Chỉ ghi nhận | Sprint 4 | Nghiệp vụ cọc |
| OD-09 | Ngày đến hạn/nhắc hạn | Ngày 5 + mốc −3/0/+3/+7 | Sprint 6 | Hóa đơn |
| OD-10 | Public web marketplace/SEO | Không làm MVP | Sau MVP | Phạm vi |
| OD-11 | Tư vấn pháp lý hợp đồng/e-sign | Chưa có | Trước pilot | Rủi ro pháp lý |
| OD-12 | Vùng lưu trữ dữ liệu | Chưa chọn | Sprint 0 | Compliance, chi phí |
| OD-13 | Nhà cung cấp email giao dịch | Chưa chọn | Sprint 1 | Auth/invite |
| OD-14 | Giới hạn ảnh/tin và dung lượng | 20 ảnh, 10 MB/ảnh | Sprint 3 | Chi phí, UX |

---

## Phụ lục A — Catalog thông báo mặc định

| Mã | Sự kiện | Người nhận | Kênh | Có thể tắt |
|---|---|---|---|---|
| NTF-01 | Tin đăng được duyệt/từ chối | Owner, Staff có quyền | Push + inbox | Không |
| NTF-02 | Có yêu cầu xem phòng mới | Owner, Staff có quyền | Push + inbox | Có |
| NTF-03 | Hợp đồng mới/chờ ký | Renter đại diện | Push + inbox | Không |
| NTF-04 | Hợp đồng sắp hết hạn (30 ngày) | Owner + Renter đại diện | Push + inbox | Không |
| NTF-05 | Chỉ số mới chờ xác nhận | Renter đại diện | Push + inbox | Không |
| NTF-06 | Hóa đơn mới | Renter đại diện | Push + inbox | Không |
| NTF-07 | Nhắc thanh toán/quá hạn | Renter đại diện | Push + inbox | Không |
| NTF-08 | Thanh toán được xác nhận/từ chối | Renter đại diện | Push + inbox | Không |
| NTF-09 | Ticket mới/cập nhật | Owner/Staff hoặc Renter đại diện | Push + inbox | Có |
| NTF-10 | Thông báo chung của Property | Renter đại diện active | Push + inbox | Có |
| NTF-11 | Tài khoản bị khóa/mở khóa | Owner | Email + inbox | Không |
| NTF-12 | Lời mời Staff/Renter | Người được mời | Email/link | Không |
| NTF-13 | Biên bản check-in/check-out chờ xác nhận/nhắc lại | Renter đại diện | Push + inbox | Không |

---

## Phụ lục B — Checklist review BRD

- [ ] Mọi `FR-*` `Must` có `AC-*` trực tiếp hoặc theo nhóm tại Phụ lục C.
- [ ] Mọi `AC-*` kiểm thử được và không mâu thuẫn `BR-*`.
- [ ] Mọi trạng thái có state machine và transition hợp lệ.
- [ ] Mọi bảng/document tenant-scoped (PostgreSQL + MongoDB) có `TenantId` + chiến lược index.
- [ ] Ràng buộc nghiệp vụ nằm ở write model; read model rebuild được và không phải nguồn sự thật.
- [ ] Mọi quyền nhạy cảm có audit + cảnh báo.
- [ ] Mọi thao tác của actor đã xác thực có audit; Owner xem được audit của mình + activity log Staff.
- [ ] Mọi luồng có error/empty/retry state.
- [ ] Không còn nội dung thanh toán online/billing/chat nhóm.
- [ ] Các `OD-*` đã có người chốt và deadline.

---

## Phụ lục C — Ma trận truy vết yêu cầu → tiêu chí chấp nhận

| Nhóm yêu cầu | FR | AC bao phủ |
|---|---|---|
| Tài khoản, tenant, RBAC, session | FR-ACC-01..09 | AC-TEN-01, AC-TEN-02, AC-RBAC-01..05, AC-SEC-01, AC-SUS-01 |
| Property, Room, bảng giá | FR-PRP-01..07 | AC-TEN-01, AC-TEN-02, AC-RBAC-02, AC-LST-03, AC-LSE-01 |
| Tin đăng, marketplace, viewing request | FR-LST-01..13 | AC-LST-01..05, AC-UPL-01, AC-SEC-02 |
| Hợp đồng, người ở, CCCD, ký | FR-LSE-01..14 | AC-LSE-01..06, AC-RBAC-01, AC-TEN-01, AC-SUS-01 |
| Biên bản tình trạng | FR-CND-01..11 | AC-CND-01..06, AC-UPL-01 |
| Chỉ số, hóa đơn, thanh toán | FR-MTR-01..16 | AC-MTR-01..03, AC-INV-01..06, AC-SUS-01 |
| Thông báo | FR-NTF-01..08 | AC-NTF-01, AC-NTF-02, AC-SUS-01 |
| Ticket | FR-TKT-01..08 | AC-TKT-01, AC-TKT-02, AC-RBAC-02 |
| Audit | FR-ADT-01..07 | AC-ADT-01..04, AC-RBAC-04 |
| NFR bảo mật/hiệu năng/độ tin cậy/web | NFR-SEC-*, NFR-PERF-*, NFR-AVL-*, NFR-WEB-*, NFR-UX-* | AC-PERF-01, AC-UPL-01, AC-SEC-01, AC-SEC-02, AC-REST-01, AC-TEN-02, AC-ARCH-01, AC-UX-01 |

> FR đánh dấu `NÊN` có thể không có AC riêng trong MVP; khi đưa vào sprint phải bổ sung AC tương ứng.
> AC không thay thế test tự động: mỗi AC `Must` phải có ít nhất một test tự động hoặc test thủ công được ghi lại trong PR.
