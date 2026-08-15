package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class MaintenanceRecord {
	private Long maintenanceId;
	private Long assetId;
	private Long incidentId;
	private Integer quantity;
	private Long requestedBy;
	private String description;
	private LocalDateTime requestedAt;
	private String status;
	private Long approvedBy;
	private LocalDateTime approvedAt;
	private String approvalNote;
	private LocalDateTime repairStartedAt;
	private LocalDateTime repairCompletedAt;
	private String repairResult;
	private String note;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public MaintenanceRecord() {
	}

	public MaintenanceRecord(Long maintenanceId, Long assetId, Long incidentId, Integer quantity, Long requestedBy,
			String description, LocalDateTime requestedAt, String status, Long approvedBy, LocalDateTime approvedAt,
			String approvalNote, LocalDateTime repairStartedAt, LocalDateTime repairCompletedAt, String repairResult,
			String note, LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.maintenanceId = maintenanceId;
		this.assetId = assetId;
		this.incidentId = incidentId;
		this.quantity = quantity;
		this.requestedBy = requestedBy;
		this.description = description;
		this.requestedAt = requestedAt;
		this.status = status;
		this.approvedBy = approvedBy;
		this.approvedAt = approvedAt;
		this.approvalNote = approvalNote;
		this.repairStartedAt = repairStartedAt;
		this.repairCompletedAt = repairCompletedAt;
		this.repairResult = repairResult;
		this.note = note;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getMaintenanceId() {
		return maintenanceId;
	}

	public void setMaintenanceId(Long maintenanceId) {
		this.maintenanceId = maintenanceId;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public Long getIncidentId() {
		return incidentId;
	}

	public void setIncidentId(Long incidentId) {
		this.incidentId = incidentId;
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

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
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

	public LocalDateTime getRepairStartedAt() {
		return repairStartedAt;
	}

	public void setRepairStartedAt(LocalDateTime repairStartedAt) {
		this.repairStartedAt = repairStartedAt;
	}

	public LocalDateTime getRepairCompletedAt() {
		return repairCompletedAt;
	}

	public void setRepairCompletedAt(LocalDateTime repairCompletedAt) {
		this.repairCompletedAt = repairCompletedAt;
	}

	public String getRepairResult() {
		return repairResult;
	}

	public void setRepairResult(String repairResult) {
		this.repairResult = repairResult;
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
