<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="app" uri="/WEB-INF/app.tld"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Thêm thiết bị | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <style>
        .form-note{margin:0 0 12px;color:var(--muted);font-size:11px;line-height:1.5}.item-table{width:100%;min-width:930px}.item-table input,.item-table select{width:100%;min-height:32px;padding:0 8px;border:1px solid var(--line);border-radius:6px;color:var(--ink);background:#fff;font-size:10.5px}.item-table th{white-space:nowrap}.item-table td{padding:8px 6px;vertical-align:top}.item-table th:nth-child(6),.item-table th:nth-child(7),.item-table td:nth-child(6),.item-table td:nth-child(7){display:none}.quantity-control{display:flex;align-items:center;gap:8px}.quantity-control input{width:100px}.form-actions{display:flex;gap:8px;align-items:center}.error-message{margin-bottom:10px;padding:9px 12px;border:1px solid #f1c1c1;border-radius:7px;color:#9a3030;background:#fff0f0;font-size:11px}.item-image-cell{min-width:168px}.item-image-file{position:absolute;width:1px;height:1px;opacity:0;overflow:hidden}.image-picker{display:flex;align-items:center;gap:8px;min-height:58px;padding:6px 8px;border:1px dashed #9fcbe4;border-radius:8px;background:linear-gradient(135deg,#f4fbff,#edf6ff);color:#166b9c;cursor:pointer;transition:.15s ease}.image-picker:hover{border-color:#168ac7;background:#e8f7ff;transform:translateY(-1px)}.image-picker-preview{display:grid;flex:0 0 46px;width:46px;height:46px;place-items:center;overflow:hidden;border-radius:6px;background:#ddecf7}.image-picker-preview img{width:100%;height:100%;object-fit:cover}.image-picker-preview svg{width:22px;height:22px;fill:none;stroke:currentColor;stroke-width:1.7}.image-picker-copy{display:flex;flex-direction:column;gap:2px;font-size:10px;font-weight:700}.image-picker-copy small{color:#5b7690;font-size:9px;font-weight:500}.image-file-note{margin:4px 0 0;color:#8494a1;font-size:8.5px;line-height:1.35}.shared-image-box{display:flex;align-items:center;gap:14px;margin:0 0 14px;padding:12px;border:1px solid #c9e3f2;border-radius:10px;background:linear-gradient(110deg,#f3fbff,#f7f5ff)}.shared-image-box .image-picker{width:min(100%,420px);min-height:70px;background:#fff}.shared-image-box .image-picker-preview{flex-basis:56px;width:56px;height:56px}.shared-image-help{margin:0;color:#587287;font-size:10px;line-height:1.55}.shared-image-help strong{display:block;color:#173a53;font-size:11px}
    </style>
</head>
<body class="${assetRole == 'mentor' ? 'mentor-page' : 'lab-manager-page'}">
<c:set var="activeMenu" value="assets" scope="request"/>
<div class="app-shell">
    <c:choose><c:when test="${assetRole == 'mentor'}"><%@ include file="../../mentor/includes/sidebar.jspf" %></c:when><c:otherwise><%@ include file="../includes/sidebar.jspf" %></c:otherwise></c:choose>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Mở thanh điều hướng" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>Thêm thiết bị</h1><p>Tạo một nhóm thiết bị và sinh mã riêng cho từng sản phẩm</p></div></div><div class="topbar-actions"><a class="btn-secondary" href="${assetBasePath}">Quay lại danh sách</a></div></header>
        <section class="content-area">
            <div class="content-heading"><div><p class="eyebrow">QUẢN LÝ THIẾT BỊ</p><h2>Thông tin nhóm sản phẩm</h2></div></div>
            <c:if test="${not empty message}"><div class="error-message"><c:out value="${message}"/></div></c:if>
            <form method="post" enctype="multipart/form-data" action="${assetBasePath}/new">
                <input type="hidden" name="csrfToken" value="${sessionScope.csrfToken}">
                <article class="panel form-section"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-box"/></svg></span><h3>Thông tin chung</h3></div></header>
                    <div class="form-grid">
                        <div class="form-group"><label for="assetCode">Mã thiết bị gốc</label><input class="form-control" id="assetCode" name="assetCode" value="<c:out value='${param.assetCode}'/>" placeholder="VD: LAPTOP-DELL" required><small>Mã sản phẩm riêng sẽ được sinh dạng LAPTOP-DELL-0001.</small></div>
                        <div class="form-group"><label for="assetName">Tên thiết bị</label><input class="form-control" id="assetName" name="assetName" value="<c:out value='${param.assetName}'/>" placeholder="VD: Laptop Dell Latitude" required></div>
                        <div class="form-group"><label for="categoryId">Loại thiết bị</label><select class="form-control" id="categoryId" name="categoryId" required><option value="">Chọn loại thiết bị</option><c:forEach items="${categories}" var="category"><option value="${category.categoryId}" ${param.categoryId == category.categoryId ? 'selected' : ''}><c:out value="${category.categoryName}"/></option></c:forEach></select></div>
                        <div class="form-group"><label for="assetType">Dạng tài sản</label><select class="form-control" id="assetType" name="assetType" required><option value="">Chọn dạng tài sản</option><option value="FIXED" ${param.assetType == 'FIXED' ? 'selected' : ''}>Tài sản cố định — không cho mượn</option><option value="BORROWABLE" ${param.assetType == 'BORROWABLE' ? 'selected' : ''}>Tài sản có thể mượn</option></select><small>Tài sản cố định vẫn được kiểm kê, bảo trì và thanh lý.</small></div>
                        <div class="form-group"><label for="quantity">Số lượng sản phẩm</label><div class="quantity-control"><input class="form-control" id="quantity" name="quantity" type="number" min="1" max="100" value="${empty quantity ? 1 : quantity}" required><span>sản phẩm</span></div><small>Mỗi sản phẩm có mã và trạng thái riêng.</small></div>
                        <div class="form-group full-width"><label for="description">Mô tả chung</label><textarea class="form-control" id="description" name="description" placeholder="Thông tin dùng chung cho nhóm thiết bị"><c:out value="${param.description}"/></textarea></div>
                    </div>
                </article>
                <article class="panel form-section" style="margin-top:12px"><header class="panel-header"><div class="panel-title"><span class="title-icon"><svg><use href="#i-list"/></svg></span><h3>Thông tin từng sản phẩm</h3></div></header>
                    <p class="form-note">Bạn có thể chọn một ảnh dùng chung cho tất cả sản phẩm. Nếu sản phẩm nào có ảnh khác, hãy chọn ảnh riêng ngay tại dòng đó để thay thế ảnh chung.</p>
                    <div class="shared-image-box">
                        <input class="item-image-file" id="sharedImageFile" name="sharedImageFile" type="file" accept="image/jpeg,image/png,image/webp">
                        <label class="image-picker" for="sharedImageFile"><span class="image-picker-preview" id="sharedImagePreview"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="16" rx="2"></rect><circle cx="8.5" cy="9" r="1.5"></circle><path d="m4 18 5-5 3.5 3.5 2.5-2.5 5 4"></path></svg></span><span class="image-picker-copy">Chọn ảnh dùng chung<small>Áp dụng cho toàn bộ sản phẩm bên dưới</small></span></label>
                        <p class="shared-image-help"><strong>Chỉ cần chọn một lần</strong>JPG, PNG hoặc WebP · tối đa 5 MB.<br>Ảnh riêng của từng dòng sẽ được ưu tiên nếu có.</p>
                    </div>
                    <div class="table-scroll"><table class="item-table"><thead><tr><th>#</th><th>Serial</th><th>Ảnh thiết bị</th><th>Tình trạng</th><th>Trạng thái</th><th>Ngày mua</th><th>Bảo hành đến</th><th>Ghi chú</th></tr></thead><tbody id="itemRows"></tbody></table></div>
                </article>
                <div class="form-actions" style="margin-top:12px"><button class="primary-button" type="submit" name="action" value="create">Tạo sản phẩm</button><a class="btn-secondary" href="${assetBasePath}">Hủy</a></div>
            </form>
        </section>
    </main>
</div>
<script>
const rowHost=document.getElementById('itemRows'), quantityInput=document.getElementById('quantity'), sharedImageInput=document.getElementById('sharedImageFile'), sharedImagePreview=document.getElementById('sharedImagePreview'), imageIcon='<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="16" rx="2"></rect><circle cx="8.5" cy="9" r="1.5"></circle><path d="m4 18 5-5 3.5 3.5 2.5-2.5 5 4"></path></svg>';
function row(index){const imageId='itemImageFile'+index;return '<tr><td>'+(index+1)+'</td><td><input name="itemSerialNumber" maxlength="100" placeholder="Serial"></td><td class="item-image-cell"><input class="item-image-file item-specific-image" id="'+imageId+'" name="'+imageId+'" type="file" accept="image/jpeg,image/png,image/webp"><label class="image-picker" for="'+imageId+'"><span class="image-picker-preview">'+imageIcon+'</span><span class="image-picker-copy">Chọn ảnh riêng<small>Không chọn sẽ dùng ảnh chung</small></span></label><p class="image-file-note">JPG, PNG, WebP · tối đa 5 MB</p></td><td><select name="itemCondition"><option value="GOOD">Tốt</option><option value="FAIR">Khá</option></select></td><td><span class="status available">Sẵn sàng</span><small class="asset-meta">Trạng thái ban đầu</small></td><td><input name="itemPurchaseDate" type="date"></td><td><input name="itemWarrantyUntil" type="date"></td><td><input name="itemNote" maxlength="500" placeholder="Ghi chú"></td></tr>';}
function validImage(file){return file&&['image/jpeg','image/png','image/webp'].includes(file.type)&&file.size<=5*1024*1024;}
function showPreview(preview,file){if(!file){preview.innerHTML=imageIcon;return;}const image=document.createElement('img'),url=URL.createObjectURL(file);image.onload=()=>URL.revokeObjectURL(url);image.src=url;image.alt='Xem trước ảnh thiết bị';preview.replaceChildren(image);}
function applySharedPreviews(){const sharedFile=sharedImageInput.files[0];rowHost.querySelectorAll('.item-specific-image').forEach(input=>{if(!input.files[0])showPreview(input.parentElement.querySelector('.image-picker-preview'),sharedFile);});}
function renderRows(){let quantity=Math.max(1,Math.min(100,Number(quantityInput.value)||1));quantityInput.value=quantity;rowHost.innerHTML=Array.from({length:quantity},(_,index)=>row(index)).join('');applySharedPreviews();}
quantityInput.addEventListener('input',renderRows);
sharedImageInput.addEventListener('change',()=>{const file=sharedImageInput.files[0];if(file&&!validImage(file)){sharedImageInput.value='';showPreview(sharedImagePreview,null);applySharedPreviews();alert('Ảnh phải là JPG, PNG hoặc WebP và không vượt quá 5 MB.');return;}showPreview(sharedImagePreview,file);applySharedPreviews();});
rowHost.addEventListener('change',event=>{const input=event.target;if(!input.matches('.item-specific-image'))return;const preview=input.parentElement.querySelector('.image-picker-preview'),file=input.files[0];if(file&&!validImage(file)){input.value='';showPreview(preview,sharedImageInput.files[0]);alert('Ảnh phải là JPG, PNG hoặc WebP và không vượt quá 5 MB.');return;}showPreview(preview,file||sharedImageInput.files[0]);});
renderRows();
</script>
</body>
</html>
