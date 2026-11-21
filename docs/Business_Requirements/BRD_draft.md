# Nền tảng SaaS Quản lý & Cho thuê Phòng trọ — Mô tả nghiệp vụ

> Trạng thái: **Bản nháp v0.1** — để chỉnh sửa trước khi bàn kiến trúc SaaS và tech stack.
> Mục đích dự án: học backend (thiết kế domain, multi-tenant, auth, thông báo, v.v.).
> Các mục đánh dấu `❓` là câu hỏi mở cần bạn quyết định.

---

## 1. Tổng quan

Một **nền tảng trung tâm** cung cấp dịch vụ cho **chủ trọ** (đóng phí thành viên một lần, mô hình SaaS tương tự KiotViet cho người bán hàng) để:

1. Quản lý nhà trọ / phòng / khách thuê / hợp đồng / điện nước.
2. Quảng cáo phòng trống lên một **kênh chung** (marketplace) do nền tảng vận hành.
3. Lập hợp đồng điện tử kèm **biên bản tình trạng phòng có hình ảnh**, giảm tranh chấp khi trả phòng.
4. Liên lạc với khách thuê (thông báo đẩy) kể cả khi chủ trọ không ở cùng nơi.

Khách thuê dùng một app riêng để xem hợp đồng, hóa đơn điện nước, nhận thông báo.

### Vấn đề cần giải quyết

| Đối tượng | Vấn đề hiện tại |
|---|---|
| Chủ trọ | Quản lý bằng sổ tay / Excel / Zalo; khó đăng phòng trống; tranh cãi khi trả phòng; ghi điện nước thủ công |
| Khách thuê | Khó tìm phòng uy tín; không rõ giá điện nước; không có bằng chứng tình trạng phòng lúc nhận |
| Chủ trọ ở xa | Khó thông báo đồng loạt, khó theo dõi tình hình trọ |

---

## 2. Thuật ngữ (tránh nhầm lẫn)

> Trong SaaS, "tenant" là **khách hàng của nền tảng** = chủ trọ. Còn người ở trọ là "khách thuê". Nên thống nhất tên gọi ngay từ đầu.

| Thuật ngữ | Ý nghĩa |
|---|---|
| **Platform** | Nền tảng trung tâm do bạn vận hành |
| **Owner** (chủ trọ) | Khách hàng đóng phí thành viên của nền tảng (SaaS tenant) |
| **Renter** (khách thuê) | Người thuê phòng của Owner |
| **Seeker** (người tìm phòng) | Người dùng/ẩn danh xem tin đăng, chưa phải Renter |
| **Staff** (nhân viên/quản lý) | Người được Owner mời và gán quyền để trông trọ thay |
| **Property** (nhà trọ) | Một địa điểm/dãy trọ của Owner |
| **Room** (phòng) | Một phòng thuộc Property |
| **Listing** (tin đăng) | Tin quảng cáo một phòng trống trên marketplace |
| **Lease** (hợp đồng) | Hợp đồng thuê giữa Owner và Renter cho một Room |
| **Condition Report** (biên bản tình trạng) | Bản ghi tình trạng phòng kèm ảnh tại thời điểm giao/nhận |

---

## 3. Các vai trò (Actors)

### 3.1 Platform Admin
- Quản lý danh sách Owner, mức phí thành viên, trạng thái đóng phí của từng Owner.
- Duyệt tin đăng của Owner, và cấu hình cho từng Owner được đăng tin không cần duyệt (xem 4.3); xử lý báo cáo vi phạm.
- Xem thống kê toàn nền tảng.

### 3.2 Owner (Chủ trọ)
- Đăng ký, đóng phí thành viên (một lần) để kích hoạt tài khoản.
- Tạo & quản lý Property, Room, bảng giá.
- Đăng tin phòng trống (chụp ảnh, mô tả, giá).
- Tạo hợp đồng, biên bản tình trạng phòng, ghi chỉ số điện nước, phát hành hóa đơn.
- Gửi thông báo cho khách thuê.
- Có thể thêm **nhân viên/quản lý** (người trông trọ thay, xem mục 3.5). Owner **chủ động gán quyền** cho từng người theo mô hình RBAC.

### 3.3 Renter (Khách thuê)
- Nhận lời mời/hợp đồng, xác nhận & ký.
- Xem hợp đồng, biên bản tình trạng phòng, hóa đơn điện nước hàng tháng.
- Nhận thông báo từ chủ trọ; gửi yêu cầu (báo hỏng, xin sửa chữa).
- Yêu cầu trả phòng, xác nhận biên bản trả phòng.

### 3.4 Seeker (Người tìm phòng)
- Duyệt/tìm kiếm tin đăng trên marketplace (không cần đăng nhập).
- Liên hệ chủ trọ / đặt lịch xem phòng.

### 3.5 Staff (Nhân viên / Quản lý trọ) và phân quyền RBAC
- Là người được Owner mời để trông trọ thay, làm việc **trong không gian dữ liệu của Owner đó**.
- Owner **tự tạo role và gán quyền** (permission) cho từng Staff; nền tảng cung cấp sẵn một số role mẫu để Owner dùng nhanh.
- Quyền có thể giới hạn theo **phạm vi** (ví dụ chỉ một số Property nhất định) và theo **chức năng** (ví dụ chỉ được nhập điện nước, không được xem hợp đồng hay đổi giá).
- Ví dụ nhóm quyền: quản lý phòng, đăng tin, tạo/xem hợp đồng, chụp biên bản, nhập điện nước, ghi nhận thanh toán, gửi thông báo, quản lý Staff.
- Staff không có quyền với phí thành viên và thiết lập tài khoản Owner (chỉ Owner chính).
- Mọi thao tác của Staff được ghi audit log kèm danh tính người thực hiện.

---

## 4. Các phân hệ nghiệp vụ (Modules)

### 4.1 Tài khoản & Phí thành viên (Platform)
- Đăng ký / đăng nhập cho Owner và Renter.
- Owner đóng **phí thành viên một lần**, mức phí **như nhau cho mọi Owner** (không chia gói, không giới hạn theo số phòng).
- Trạng thái tài khoản Owner: `Chưa kích hoạt` (chưa đóng phí) → `Hoạt động` → `Bị khóa` (Platform Admin khóa khi vi phạm).
- Mỗi Owner có **không gian dữ liệu riêng**, không thấy dữ liệu của Owner khác.

### 4.2 Quản lý Nhà trọ & Phòng
- Property: tên, địa chỉ, tiện ích chung, nội quy.
- Room: mã phòng, diện tích, giá thuê, tiền cọc, tiện nghi, trạng thái.
- Trạng thái phòng: `Trống` → `Đã đặt cọc/giữ chỗ` → `Đang thuê` → `Sắp trả` → `Đang sửa chữa/Ngưng cho thuê`.
- Danh mục đơn giá: điện, nước, internet, rác, giữ xe, dịch vụ khác (cố định hoặc theo chỉ số).

### 4.3 Đăng tin & Quảng cáo phòng trống
- Owner chụp ảnh trực tiếp trong app (hoặc tải lên), thêm mô tả, giá, ngày có thể vào ở.
- Tin đăng liên kết với một Room; Room chuyển sang `Đã thuê` thì tin **tự động ẩn/đóng**.
- Marketplace công khai: tìm kiếm theo khu vực, giá, diện tích, tiện nghi.
- Seeker liên hệ / đặt lịch xem phòng; Owner nhận thông báo.
- **Duyệt tin:** mặc định mọi tin đăng phải được Platform Admin duyệt trước khi hiển thị trên marketplace. Admin có thể **bật quyền đăng không cần duyệt cho từng Owner** (cấu hình theo Owner).
- Trạng thái tin đăng: `Nháp` → `Chờ duyệt` → `Đang hiển thị` / `Bị từ chối` → `Đã đóng`. Owner được duyệt miễn kiểm duyệt thì tin đi thẳng từ `Nháp` sang `Đang hiển thị`.
- **Không có tin nổi bật hay quảng cáo trả phí**: mọi tin đăng được đối xử như nhau.

### 4.4 Hợp đồng thuê (Lease)
- Owner tạo hợp đồng từ một Room trống: thông tin Renter, thời hạn, giá thuê, tiền cọc, chu kỳ thanh toán, đơn giá điện nước, điều khoản/nội quy.
- Renter nhận hợp đồng trên app, xem và **xác nhận/ký điện tử**.
- Vòng đời: `Nháp` → `Chờ khách xác nhận` → `Đang hiệu lực` → `Sắp hết hạn` → `Đã kết thúc` / `Đã hủy`.
- Gia hạn, điều chỉnh giá (có lưu lịch sử phiên bản).
- Hợp đồng có thể có nhiều người ở (người đại diện + người ở cùng). **Lưu CCCD** của từng người ở dưới dạng **bản chụp/scan (ảnh) hai mặt**, đính vào hồ sơ hợp đồng. Vì là dữ liệu nhạy cảm, ảnh CCCD chỉ những người được cấp quyền mới xem được (xem mục 7).
- Sau khi ký, nội dung hợp đồng **không sửa trực tiếp** — mọi thay đổi tạo phụ lục/phiên bản mới.

### 4.5 Biên bản tình trạng phòng (Condition Report)
- **Lúc giao phòng (check-in)**: Owner chụp ảnh từng khu vực (tường, sàn, cửa, thiết bị, đồ đạc), ghi chú tình trạng, đính vào hợp đồng. Renter xem và xác nhận (hoặc phản hồi bổ sung).
- **Lúc trả phòng (check-out)**: chụp lại cùng các khu vực để Owner/Staff đối chiếu với biên bản ban đầu.
- Ghi nhận hư hỏng phát sinh, chi phí khấu trừ vào tiền cọc, hoàn cọc.
- Ảnh có **dấu thời gian** và không chỉnh sửa sau khi chốt, để làm bằng chứng.
- Ảnh check-in và check-out được **lưu theo từng khu vực** và hiển thị trên giao diện dễ theo dõi, để Owner/Staff tự xem và đối chiếu bằng mắt. **Không có chức năng so sánh tự động** hay màn hình so sánh trực tiếp.

### 4.6 Điện nước & Hóa đơn hàng tháng
- Owner (hoặc nhân viên) nhập chỉ số điện/nước mỗi kỳ (có thể chụp ảnh đồng hồ làm bằng chứng).
- Hệ thống tự tính: tiền phòng + điện + nước + dịch vụ khác = tổng hóa đơn.
- Renter thấy **bảng giá** và **hóa đơn chi tiết** hàng tháng, lịch sử các tháng trước.
- Trạng thái hóa đơn: `Chưa thanh toán` → `Đã thanh toán` / `Quá hạn`.
- **Không tích hợp thanh toán online hay ví điện tử.** Việc chuyển khoản diễn ra ngoài app; Renter hoặc Owner chỉ cần **lưu thông tin chuyển khoản thành công lên app** (số tiền, thời gian, ảnh biên lai hoặc ghi chú) vào hóa đơn tương ứng.

### 4.7 Thông báo & Liên lạc
- Thông báo đẩy (push) / trong app cho các sự kiện: hợp đồng mới, hóa đơn mới, nhắc đóng tiền, sắp hết hạn hợp đồng, thông báo chung từ chủ trọ.
- **Thông báo theo Property**: Owner gửi thông báo một lần, tất cả Renter của nhà trọ đó nhận được push (cho trường hợp chủ ở xa).
- Renter gửi yêu cầu/báo sự cố cho Owner (sửa chữa, vấn đề chung).
- **Không có group chat**: thông báo chỉ là **push notification** một chiều (chủ → khách).

---

## 5. Luồng nghiệp vụ chính

### 5.1 Onboarding chủ trọ
1. Owner đăng ký tài khoản → đóng phí thành viên (một lần) → tài khoản được kích hoạt.
2. Tạo Property → thêm Room → thiết lập bảng giá.
3. Sẵn sàng đăng tin / tạo hợp đồng.

### 5.2 Đăng tin phòng trống → có khách
1. Owner chụp ảnh phòng trống, nhập giá & mô tả → gửi tin. Tin vào trạng thái chờ duyệt (hoặc hiển thị ngay nếu Owner được miễn duyệt).
2. Seeker tìm thấy tin trên marketplace → liên hệ / hẹn xem phòng.
3. Owner chốt khách → tạo hợp đồng (xem 5.3). Tin tự đóng.

### 5.3 Lập hợp đồng & giao phòng
1. Owner tạo hợp đồng, mời Renter (qua số điện thoại/email/link).
2. Renter tạo tài khoản (nếu chưa có), xem hợp đồng.
3. Owner chụp **biên bản tình trạng phòng (check-in)**, đính vào hợp đồng.
4. Renter xác nhận biên bản + ký hợp đồng.
5. Hợp đồng `Đang hiệu lực`, Room chuyển `Đang thuê`, Renter bắt đầu nhận thông báo của Property.

### 5.4 Chu kỳ hàng tháng
1. Cuối kỳ: Owner nhập chỉ số điện nước.
2. Hệ thống tạo hóa đơn → Renter nhận thông báo.
3. Renter chuyển khoản (ngoài app) → Renter hoặc Owner lưu thông tin chuyển khoản lên hóa đơn → hóa đơn `Đã thanh toán`.
4. Quá hạn → hệ thống nhắc tự động.

### 5.5 Trả phòng
1. Renter gửi yêu cầu trả phòng (hoặc hợp đồng hết hạn).
2. Owner chụp **biên bản check-out**, đối chiếu với biên bản ban đầu.
3. Chốt hóa đơn cuối (điện nước kỳ cuối, khấu trừ hư hỏng nếu có).
4. Hoàn tiền cọc → hợp đồng `Đã kết thúc` → Room về `Trống` → Owner có thể đăng tin lại.

---

## 6. Quy tắc nghiệp vụ (Business rules) — bản đầu

1. Một Room tại một thời điểm chỉ có **tối đa một hợp đồng đang hiệu lực**.
2. Chỉ Room ở trạng thái `Trống` mới được đăng tin / tạo hợp đồng mới.
3. Owner chỉ truy cập được dữ liệu của chính mình; Renter chỉ thấy dữ liệu liên quan hợp đồng của mình.
4. Hợp đồng và biên bản đã chốt là **bất biến**; thay đổi phải tạo phiên bản/phụ lục mới.
5. Chỉ số điện nước mới phải **≥ chỉ số kỳ trước** (trừ trường hợp thay đồng hồ, cần ghi chú).
6. Owner chưa kích hoạt hoặc bị khóa: không đăng tin mới/tạo hợp đồng mới, nhưng Renter vẫn **xem được dữ liệu hiện có** (không để khách thuê mất quyền truy cập hợp đồng của mình).
7. Mọi thao tác quan trọng (ký, chốt biên bản, đổi giá, ghi nhận thanh toán) phải có **nhật ký (audit log)**.
8. Một Renter có thể thuê nhiều phòng, ở nhiều Owner khác nhau — dùng **một tài khoản duy nhất**.
9. Staff chỉ làm được những gì Owner đã gán qua role/permission, và chỉ trong phạm vi Property được giao. Chỉ Owner chính mới quản lý Staff và tài khoản.

---

## 7. Yêu cầu phi chức năng (mức nghiệp vụ)

- **Cách ly dữ liệu** giữa các Owner.
- **Bảo mật dữ liệu cá nhân** (CCCD, số điện thoại, ảnh phòng).
- **Truy vết**: lưu lịch sử thay đổi hợp đồng, hóa đơn, biên bản.
- **Dùng được trên điện thoại** là ưu tiên (chụp ảnh, nhập chỉ số tại chỗ).
- **Chịu được mạng yếu** khi upload ảnh. **Không cần offline mode.**

---

## 8. Phạm vi

### MVP đề xuất
- Đăng ký/đăng nhập Owner & Renter
- Quản lý Property / Room
- Đăng tin phòng trống + tìm kiếm cơ bản
- Hợp đồng + biên bản tình trạng phòng (ảnh)
- Nhập điện nước + hóa đơn hàng tháng
- Thông báo theo Property

### Để sau (v2+)
- Chữ ký số pháp lý
- Đánh giá/review chủ trọ & khách
- Báo cáo doanh thu cho Owner, dashboard cho Platform Admin
- Đa ngôn ngữ

---

## 9. Ghi chú kiến trúc (đã chọn hướng multi-tenancy, phần còn lại chưa quyết định)

Ý tưởng ban đầu là mỗi chủ trọ có backend/domain riêng. Vì dự án do một người làm và cần dễ deploy, hướng được chọn bên dưới thay thế ý tưởng đó. Phần này thuộc về **kiến trúc SaaS**:

- **Mô hình multi-tenancy (đã chọn): một backend, một database, một schema chung, tách dữ liệu bằng `TenantId` (chính là Owner).**
  - **Cách hoạt động:** mọi bảng dữ liệu của Owner (Property, Room, Lease, hóa đơn, Staff...) có cột `TenantId`. Backend xác định tenant từ người đăng nhập (token) và **tự động lọc** mọi truy vấn theo `TenantId` ở một chỗ duy nhất (ví dụ global query filter của ORM), để không phải nhớ thêm điều kiện lọc ở từng câu truy vấn.
  - **Vì sao chọn:** chỉ cần deploy và vận hành **một** backend và **một** database; thêm Owner mới chỉ là thêm một dòng dữ liệu, không phải tạo hạ tầng mới; migration chạy một lần cho tất cả. Đây cũng là cách phổ biến nhất ở các SaaS thực tế quy mô nhỏ đến vừa, và đủ để thể hiện kiến thức về cách ly dữ liệu, auth và phân quyền.
  - **Phải cẩn thận:** quên lọc `TenantId` là lỗi lộ dữ liệu giữa các Owner, nên cần viết test kiểm tra cách ly dữ liệu giữa hai tenant.
  - **Không phải dữ liệu nào cũng thuộc tenant:** tài khoản người dùng (một Renter có thể thuê ở nhiều Owner, xem quy tắc 8), danh sách tin đăng trên marketplace (công khai cho Seeker) và dữ liệu quản trị của Platform nằm ở phạm vi **toàn nền tảng**. Renter xem hợp đồng/hóa đơn của mình theo `RenterId`, xuyên qua nhiều tenant.
  - **Các hướng đã cân nhắc và không chọn:** schema riêng hoặc database riêng cho mỗi Owner (cách ly mạnh hơn nhưng migration và vận hành phức tạp, tốn tài nguyên), deploy riêng cho mỗi Owner (đắt và khó quản lý, chỉ hợp khi khách hàng yêu cầu tách hẳn).
  - **Đường nâng cấp:** nếu sau này cần, có thể chuyển một Owner lớn sang database riêng mà không đổi nghiệp vụ, miễn là mọi truy cập dữ liệu đều đi qua lớp lọc tenant ở trên.
- Tách app: app Owner, app Renter, hay **một app với hai vai trò**?
- Marketplace công khai: vì dùng chung database nên chỉ cần truy vấn các tin ở trạng thái `Đang hiển thị` của mọi tenant, không cần cơ chế đồng bộ dữ liệu.
- Tech stack và lộ trình triển khai.

---

## 10. Danh sách câu hỏi mở (tổng hợp)

1. Phí thành viên: có cho dùng thử trước khi đóng không, có hoàn phí khi Owner ngừng dùng không?
=> Tạm thời không cần quan tâm. Nhưng mà trong hệ thống này, đừng nên có nghiệp vụ về tiền bạc, thanh toán giữa owner với app. 

2. RBAC cho Staff: danh sách permission chi tiết là gì, có role mẫu sẵn không, một Staff có thuộc nhiều Owner không?
=> Một staff chỉ được thuộc một owner thôi 

3. Duyệt tin: khi tin bị từ chối, Owner nhận lý do và gửi lại thế nào? Tin đã hiển thị mà sửa nội dung có phải duyệt lại không?
=> khi bị từ chối, sẽ có field feedback cho owner xem tại sao bị từ chối. Tin đã hiển thị mà sửa nội dung thì vẫn cho hiện thông tin cũ trước khi thông tin mới được duyệt (một bản nháp?)

4. Ảnh CCCD: ai được xem (Owner, Staff quyền nào), có xóa hoặc ẩn đi khi hợp đồng kết thúc không?
=> CCCD thì thuộc vào nhóm info nhạy cảm của khác, cái này sẽ cho owner tự setup phân quyền cho staff của nó. 
kết thúc thì ẩn đi 

5. Ký điện tử ở mức "xác nhận trong app" hay cần hiệu lực pháp lý cao hơn?
=> staff chụp đồng hồ điện, bỏ lên app, người thuê nhà xác nhận hình ảnh, và gửi hình ảnh màn đã chuyển khoản ngân hàng khi đã thanh toán tiền nhà cho owner xong. (chỉ vậy thôi, đừng có làm gì phức tạp hơn về thanh toán online v.v)

6. Khi Renter tự lưu thông tin chuyển khoản, Owner có cần xác nhận lại mới chuyển hóa đơn sang `Đã thanh toán` không?
=> đúng ower xác tự xác nhận đa thanh toán

7. Renter có gửi được yêu cầu/báo sự cố cho Owner trong app không, hay chỉ nhận thông báo?
=> được phép, kiểu raise ticket cho phòng IT support í 

8. Một app hay hai app (Owner / Renter)?
=> tốt nhất thì 1 app dùng cho cả 2 thôi, cho đơn giản.
