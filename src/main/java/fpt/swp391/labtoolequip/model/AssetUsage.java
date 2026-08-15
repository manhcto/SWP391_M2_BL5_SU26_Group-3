package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class AssetUsage {
	private Long assetUsageId;
	private Long requestId;
	private Long semesterId;
	private Long studentId;
	private Long assetId;
	private Integer quantity;
	private LocalDateTime borrowedAt;
	private LocalDateTime dueAt;
	private LocalDateTime returnedAt;
	private String conditionBefore;
	private String conditionAfter;
	private String status;
	private String note;
	private Long createdBy;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public AssetUsage() {
	}

	public AssetUsage(Long assetUsageId, Long requestId, Long semesterId, Long studentId, Long assetId,
			Integer quantity, LocalDateTime borrowedAt, LocalDateTime dueAt, LocalDateTime returnedAt,
			String conditionBefore, String conditionAfter, String status, String note, Long createdBy,
			LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.assetUsageId = assetUsageId;
		this.requestId = requestId;
		this.semesterId = semesterId;
		this.studentId = studentId;
		this.assetId = assetId;
		this.quantity = quantity;
		this.borrowedAt = borrowedAt;
		this.dueAt = dueAt;
		this.returnedAt = returnedAt;
		this.conditionBefore = conditionBefore;
		this.conditionAfter = conditionAfter;
		this.status = status;
		this.note = note;
		this.createdBy = createdBy;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getAssetUsageId() {
		return assetUsageId;
	}

	public void setAssetUsageId(Long assetUsageId) {
		this.assetUsageId = assetUsageId;
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

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public Integer getQuantity() {
		return quantity;
	}

	public void setQuantity(Integer quantity) {
		this.quantity = quantity;
	}

	public LocalDateTime getBorrowedAt() {
		return borrowedAt;
	}

	public void setBorrowedAt(LocalDateTime borrowedAt) {
		this.borrowedAt = borrowedAt;
	}

	public LocalDateTime getDueAt() {
		return dueAt;
	}

	public void setDueAt(LocalDateTime dueAt) {
		this.dueAt = dueAt;
	}

	public LocalDateTime getReturnedAt() {
		return returnedAt;
	}

	public void setReturnedAt(LocalDateTime returnedAt) {
		this.returnedAt = returnedAt;
	}

	public String getConditionBefore() {
		return conditionBefore;
	}

	public void setConditionBefore(String conditionBefore) {
		this.conditionBefore = conditionBefore;
	}

	public String getConditionAfter() {
		return conditionAfter;
	}

	public void setConditionAfter(String conditionAfter) {
		this.conditionAfter = conditionAfter;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public Long getCreatedBy() {
		return createdBy;
	}

	public void setCreatedBy(Long createdBy) {
		this.createdBy = createdBy;
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
