package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class StudentProfile {
	private Long studentId;
	private Long userId;
	private String studentCode;
	private String major;
	private String cohort;
	private String status;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public StudentProfile() {
	}

	public StudentProfile(Long studentId, Long userId, String studentCode, String major, String cohort, String status,
			LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.studentId = studentId;
		this.userId = userId;
		this.studentCode = studentCode;
		this.major = major;
		this.cohort = cohort;
		this.status = status;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getStudentId() {
		return studentId;
	}

	public void setStudentId(Long studentId) {
		this.studentId = studentId;
	}

	public Long getUserId() {
		return userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	public String getStudentCode() {
		return studentCode;
	}

	public void setStudentCode(String studentCode) {
		this.studentCode = studentCode;
	}

	public String getMajor() {
		return major;
	}

	public void setMajor(String major) {
		this.major = major;
	}

	public String getCohort() {
		return cohort;
	}

	public void setCohort(String cohort) {
		this.cohort = cohort;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public LocalDateTime getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(LocalDateTime updatedAt) {
		this.updatedAt = updatedAt;
	}
}
