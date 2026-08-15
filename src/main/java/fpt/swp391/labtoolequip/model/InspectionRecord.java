package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class InspectionRecord {
	private Long inspectionId;
	private Long semesterId;
	private Long inspectedBy;
	private String inspectionType;
	private String scope;
	private LocalDateTime inspectionDate;
	private String status;
	private String result;
	private String note;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public InspectionRecord() {
	}

	public InspectionRecord(Long inspectionId, Long semesterId, Long inspectedBy, String inspectionType, String scope,
			LocalDateTime inspectionDate, String status, String result, String note, LocalDateTime createdAt,
			LocalDateTime updatedAt) {
		this.inspectionId = inspectionId;
		this.semesterId = semesterId;
		this.inspectedBy = inspectedBy;
		this.inspectionType = inspectionType;
		this.scope = scope;
		this.inspectionDate = inspectionDate;
		this.status = status;
		this.result = result;
		this.note = note;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getInspectionId() {
		return inspectionId;
	}

	public void setInspectionId(Long inspectionId) {
		this.inspectionId = inspectionId;
	}

	public Long getSemesterId() {
		return semesterId;
	}

	public void setSemesterId(Long semesterId) {
		this.semesterId = semesterId;
	}

	public Long getInspectedBy() {
		return inspectedBy;
	}

	public void setInspectedBy(Long inspectedBy) {
		this.inspectedBy = inspectedBy;
	}

	public String getInspectionType() {
		return inspectionType;
	}

	public void setInspectionType(String inspectionType) {
		this.inspectionType = inspectionType;
	}

	public String getScope() {
		return scope;
	}

	public void setScope(String scope) {
		this.scope = scope;
	}

	public LocalDateTime getInspectionDate() {
		return inspectionDate;
	}

	public void setInspectionDate(LocalDateTime inspectionDate) {
		this.inspectionDate = inspectionDate;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getResult() {
		return result;
	}

	public void setResult(String result) {
		this.result = result;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
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
