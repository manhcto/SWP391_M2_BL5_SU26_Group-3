package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class LabUsageRequestStudent {
	private Long requestId;
	private Long semesterId;
	private Long studentId;
	private String studentCode;
	private String fullName;
	private String email;
	private String cohort;
	private LocalDateTime addedAt;

	public LabUsageRequestStudent() {
	}

	public LabUsageRequestStudent(Long requestId, Long semesterId, Long studentId, LocalDateTime addedAt) {
		this.requestId = requestId;
		this.semesterId = semesterId;
		this.studentId = studentId;
		this.addedAt = addedAt;
	}

	public Long getRequestId() {
		return requestId;
	}

	public void setRequestId(Long requestId) {
		this.requestId = requestId;
	}

	public Long getSemesterId() {
		return semesterId;
	}

	public void setSemesterId(Long semesterId) {
		this.semesterId = semesterId;
	}

	public Long getStudentId() {
		return studentId;
	}

	public void setStudentId(Long studentId) {
		this.studentId = studentId;
	}

	public String getStudentCode() {
		return studentCode;
	}

	public void setStudentCode(String studentCode) {
		this.studentCode = studentCode;
	}

	public String getFullName() {
		return fullName;
	}

	public void setFullName(String fullName) {
		this.fullName = fullName;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getCohort() {
		return cohort;
	}

	public void setCohort(String cohort) {
		this.cohort = cohort;
	}

	public LocalDateTime getAddedAt() {
		return addedAt;
	}

	public void setAddedAt(LocalDateTime addedAt) {
		this.addedAt = addedAt;
	}
}
