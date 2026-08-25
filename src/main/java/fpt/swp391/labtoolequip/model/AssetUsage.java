package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class AssetUsage {
	private Long assetUsageId;
	private Long requestId;
	private Long semesterId;
	private Long internId;
	private Long assetId;
	private Long assetItemId;
	private Integer quantity;
	private LocalDateTime borrowedAt;
	private LocalDateTime dueAt;
	private LocalDateTime returnedAt;
	private String conditionBefore;
	private String conditionAfter;
	private String reportedConditionAfter;
	private LocalDateTime returnRequestedAt;
	private String verifiedConditionAfter;
	private LocalDateTime returnVerifiedAt;
	private Long returnVerifiedBy;
	private String status;
	private String note;
	private String returnNote;
	private Long createdBy;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;
	private String assetCode;
	private String assetName;
	private String assetItemTag;
	private String internName;
	private String returnVerifierName;

	public AssetUsage() {
	}

	public AssetUsage(Long assetUsageId, Long requestId, Long semesterId, Long internId, Long assetId, Long assetItemId,
			Integer quantity, LocalDateTime borrowedAt, LocalDateTime dueAt, LocalDateTime returnedAt,
			String conditionBefore, String conditionAfter, String status, String note, Long createdBy,
			LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.assetUsageId = assetUsageId;
		this.requestId = requestId;
		this.semesterId = semesterId;
		this.internId = internId;
		this.assetId = assetId;
		this.assetItemId = assetItemId;
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

	public Long getInternId() {
		return internId;
	}

	public void setInternId(Long internId) {
		this.internId = internId;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public Long getAssetItemId() {
		return assetItemId;
	}

	public void setAssetItemId(Long assetItemId) {
		this.assetItemId = assetItemId;
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
	public String getReportedConditionAfter() {
		return reportedConditionAfter;
	}
	public void setReportedConditionAfter(String value) {
		reportedConditionAfter = value;
	}
	public LocalDateTime getReturnRequestedAt() {
		return returnRequestedAt;
	}
	public void setReturnRequestedAt(LocalDateTime value) {
		returnRequestedAt = value;
	}
	public String getVerifiedConditionAfter() {
		return verifiedConditionAfter;
	}
	public void setVerifiedConditionAfter(String value) {
		verifiedConditionAfter = value;
	}
	public LocalDateTime getReturnVerifiedAt() {
		return returnVerifiedAt;
	}
	public void setReturnVerifiedAt(LocalDateTime value) {
		returnVerifiedAt = value;
	}
	public Long getReturnVerifiedBy() {
		return returnVerifiedBy;
	}
	public void setReturnVerifiedBy(Long value) {
		returnVerifiedBy = value;
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
	public String getReturnNote() {
		return returnNote;
	}
	public void setReturnNote(String returnNote) {
		this.returnNote = returnNote;
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

	public String getAssetCode() {
		return assetCode;
	}

	public void setAssetCode(String assetCode) {
		this.assetCode = assetCode;
	}

	public String getAssetName() {
		return assetName;
	}

	public void setAssetName(String assetName) {
		this.assetName = assetName;
	}

	public String getAssetItemTag() {
		return assetItemTag;
	}

	public void setAssetItemTag(String assetItemTag) {
		this.assetItemTag = assetItemTag;
	}

	public String getInternName() {
		return internName;
	}

	public void setInternName(String internName) {
		this.internName = internName;
	}

	public String getReturnVerifierName() {
		return returnVerifierName;
	}

	public void setReturnVerifierName(String returnVerifierName) {
		this.returnVerifierName = returnVerifierName;
	}
}
