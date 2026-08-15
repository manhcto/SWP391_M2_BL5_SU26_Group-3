package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class DisposalRecord {
	private Long disposalId;
	private Long assetId;
	private Long maintenanceId;
	private Integer quantity;
	private Long requestedBy;
	private String reason;
	private LocalDateTime requestedAt;
	private String status;
	private Long approvedBy;
	private LocalDateTime approvedAt;
	private String approvalNote;
	private LocalDateTime completedAt;
	private String completionNote;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public DisposalRecord() {
	}

	public DisposalRecord(Long disposalId, Long assetId, Long maintenanceId, Integer quantity, Long requestedBy,
			String reason, LocalDateTime requestedAt, String status, Long approvedBy, LocalDateTime approvedAt,
			String approvalNote, LocalDateTime completedAt, String completionNote, LocalDateTime createdAt,
			LocalDateTime updatedAt) {
		this.disposalId = disposalId;
		this.assetId = assetId;
		this.maintenanceId = maintenanceId;
		this.quantity = quantity;
		this.requestedBy = requestedBy;
		this.reason = reason;
		this.requestedAt = requestedAt;
		this.status = status;
		this.approvedBy = approvedBy;
		this.approvedAt = approvedAt;
		this.approvalNote = approvalNote;
		this.completedAt = completedAt;
		this.completionNote = completionNote;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getDisposalId() {
		return disposalId;
	}

	public void setDisposalId(Long disposalId) {
		this.disposalId = disposalId;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public Long getMaintenanceId() {
		return maintenanceId;
	}

	public void setMaintenanceId(Long maintenanceId) {
		this.maintenanceId = maintenanceId;
	}

	public Integer getQuantity() {
		return quantity;
	}

	public void setQuantity(Integer quantity) {
		this.quantity = quantity;
	}

	public Long getRequestedBy() {
		return requestedBy;
	}

	public void setRequestedBy(Long requestedBy) {
		this.requestedBy = requestedBy;
	}

	public String getReason() {
		return reason;
	}

	public void setReason(String reason) {
		this.reason = reason;
	}

	public LocalDateTime getRequestedAt() {
		return requestedAt;
	}

	public void setRequestedAt(LocalDateTime requestedAt) {
		this.requestedAt = requestedAt;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Long getApprovedBy() {
		return approvedBy;
	}

	public void setApprovedBy(Long approvedBy) {
		this.approvedBy = approvedBy;
	}

	public LocalDateTime getApprovedAt() {
		return approvedAt;
	}

	public void setApprovedAt(LocalDateTime approvedAt) {
		this.approvedAt = approvedAt;
	}

	public String getApprovalNote() {
		return approvalNote;
	}

	public void setApprovalNote(String approvalNote) {
		this.approvalNote = approvalNote;
	}

	public LocalDateTime getCompletedAt() {
		return completedAt;
	}

	public void setCompletedAt(LocalDateTime completedAt) {
		this.completedAt = completedAt;
	}

	public String getCompletionNote() {
		return completionNote;
	}

	public void setCompletionNote(String completionNote) {
		this.completionNote = completionNote;
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
