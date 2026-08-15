package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class LabUsageRequestStudent {
	private Long requestId;
	private Long semesterId;
	private Long studentId;
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

	public LocalDateTime getAddedAt() {
		return addedAt;
	}

	public void setAddedAt(LocalDateTime addedAt) {
		this.addedAt = addedAt;
	}
}
