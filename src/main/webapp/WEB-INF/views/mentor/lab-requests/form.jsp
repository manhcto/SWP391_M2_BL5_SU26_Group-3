<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${formMode == 'edit' ? 'Edit' : 'Add'} Lab Usage Request | LAB Asset</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/mentor-lab-requests.css">
</head>
<body>
<div class="app-shell">
    <c:set var="activeMenu" value="labRequests"/>
    <%@ include file="../includes/sidebar.jspf"%>
    <main class="main-content">
        <header class="topbar"><div class="heading-wrap"><button class="menu-button" id="menuButton" type="button" aria-label="Open navigation" aria-controls="sidebar" aria-expanded="false"><svg><use href="#i-menu"/></svg></button><div><h1>${formMode == 'edit' ? 'Edit request' : 'Add request'}</h1><p>Submit a student group and its recurring weekly slots</p></div></div></header>
        <section class="request-page">
            <div class="page-title-row"><div><h2>${formMode == 'edit' ? 'Update Lab Usage Request' : 'New Lab Usage Request'}</h2><p>All fields are reviewed by Admin before students receive access.</p></div><a class="secondary-button" href="${pageContext.request.contextPath}/mentor/lab-requests">Back to list</a></div>
            <c:if test="${not empty errors}"><ul class="error-list"><c:forEach var="error" items="${errors}"><li><c:out value="${error}"/></li></c:forEach></ul></c:if>
            <c:if test="${not empty databaseError}"><div class="notice error"><c:out value="${databaseError}"/></div></c:if>

            <form class="form-shell" method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/mentor/lab-requests/${formMode == 'edit' ? 'edit' : 'add'}">
                <input type="hidden" name="csrfToken" value="${csrfToken}">
                <c:if test="${formMode == 'edit'}"><input type="hidden" name="id" value="${labRequest.requestId}"></c:if>
                <section class="form-section"><h3>Request information</h3><div class="form-grid">
                    <label class="field"><span>Semester *</span><select name="semesterId" required><option value="">Select semester</option><c:forEach var="semester" items="${semesters}"><option value="${semester.semesterId}" ${labRequest.semesterId == semester.semesterId ? 'selected' : ''}><c:out value="${semester.code}"/> — <c:out value="${semester.name}"/></option></c:forEach></select></label>
                    <label class="field"><span>Group *</span><input type="text" name="groupName" maxlength="100" value="<c:out value='${labRequest.groupName}'/>" placeholder="Example: Group 03" required></label>
                    <label class="field wide"><span>Request note</span><textarea name="requestNote" placeholder="Add information for Admin..."><c:out value="${labRequest.requestNote}"/></textarea></label>
                </div></section>

                <section class="form-section"><h3>Weekly schedule</h3><div class="scroll-box"><table class="slot-table"><thead><tr><th>Day</th><th>Slot 1<br><small>07:30–09:50</small></th><th>Slot 2<br><small>10:00–12:20</small></th><th>Slot 3<br><small>12:50–15:10</small></th><th>Slot 4<br><small>15:20–17:30</small></th></tr></thead><tbody>
                    <c:forEach var="day" begin="2" end="7"><tr><td>Thứ ${day}</td><c:forEach var="slot" begin="1" end="4"><c:set var="slotKey" value="${day}-${slot}"/><td><input type="checkbox" name="slots" value="${slotKey}" aria-label="Thứ ${day}, Slot ${slot}" <c:if test="${selectedSlots.contains(slotKey)}">checked</c:if>></td></c:forEach></tr></c:forEach>
                </tbody></table></div></section>

                <section class="form-section"><div class="section-tools"><div><h3>Students</h3><span class="section-label">Student code, full name and Google email</span></div><button class="secondary-button" id="addStudent" type="button">Add student row</button></div>
                    <div class="scroll-box"><table class="student-editor"><thead><tr><th>Student code</th><th>Full name</th><th>Email</th><th></th></tr></thead><tbody id="studentRows">
                    <c:choose><c:when test="${empty labRequest.students}"><tr><td><input name="studentCode" placeholder="SE123456"></td><td><input name="studentName" placeholder="Nguyễn Văn A"></td><td><input type="email" name="studentEmail" placeholder="student@example.com"></td><td><button class="danger-button remove-student" type="button">Remove</button></td></tr></c:when><c:otherwise><c:forEach var="student" items="${labRequest.students}"><tr><td><input name="studentCode" value="<c:out value='${student.studentCode}'/>"></td><td><input name="studentName" value="<c:out value='${student.fullName}'/>"></td><td><input type="email" name="studentEmail" value="<c:out value='${student.email}'/>"></td><td><button class="danger-button remove-student" type="button">Remove</button></td></tr></c:forEach></c:otherwise></c:choose>
                    </tbody></table></div>
                    <div class="import-box"><label class="field"><span>Or import Excel (.xlsx)</span><input type="file" name="excelFile" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"></label><a class="secondary-button" href="${pageContext.request.contextPath}/mentor/lab-requests/template">Download template</a><small>Sheets: Students and Slots. Imported rows are merged with manual rows.</small></div>
                </section>
                <div class="form-actions"><a class="secondary-button" href="${pageContext.request.contextPath}/mentor/lab-requests">Cancel</a><button class="primary-button" type="submit">${formMode == 'edit' ? 'Save changes' : 'Submit request'}</button></div>
            </form>
        </section>
    </main>
</div>
<template id="studentRowTemplate"><tr><td><input name="studentCode" placeholder="SE123456"></td><td><input name="studentName" placeholder="Nguyễn Văn A"></td><td><input type="email" name="studentEmail" placeholder="student@example.com"></td><td><button class="danger-button remove-student" type="button">Remove</button></td></tr></template>
<script>
    const rows = document.getElementById('studentRows');
    document.getElementById('addStudent').addEventListener('click', () => rows.append(document.getElementById('studentRowTemplate').content.cloneNode(true)));
    rows.addEventListener('click', event => { if (event.target.classList.contains('remove-student')) event.target.closest('tr').remove(); });
</script>
</body>
</html>
