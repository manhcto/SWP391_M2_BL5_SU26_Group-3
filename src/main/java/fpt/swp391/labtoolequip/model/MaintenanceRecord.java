package fpt.swp391.labtoolequip.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class MaintenanceRecord {
	private Long maintenanceId;
	private Long assetId;
	private Long assetItemId;
	private Long incidentId;
	private Long scheduleId;
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
	private String repairOutcome;
	private Long estimatedCost;
	private Long actualCost;
	private String note;
	private String providerPhone;
	private String providerAddress;
	private String imageUrl;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	// Joined display fields
	private String assetCode;
	private String assetName;
	private String assetStatus;
	private String storageLocation;
	private String requesterName;
	private String approverName;
	private String incidentDescription;
	private String assetItemCode;
	private String scheduleTitle;
	private LocalDate scheduledDate;

	public MaintenanceRecord() {
	}

	public String getAssetStatus() {
		return assetStatus;
	}

	public void setAssetStatus(String assetStatus) {
		this.assetStatus = assetStatus;
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

	public Long getEstimatedCost() {
		return estimatedCost;
	}

	public void setEstimatedCost(Long estimatedCost) {
		this.estimatedCost = estimatedCost;
	}

	public Long getActualCost() {
		return actualCost;
	}

	public void setActualCost(Long actualCost) {
		this.actualCost = actualCost;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public String getProviderPhone() {
		return providerPhone;
	}

	public void setProviderPhone(String providerPhone) {
		this.providerPhone = providerPhone;
	}

	public String getProviderAddress() {
		return providerAddress;
	}

	public void setProviderAddress(String providerAddress) {
		this.providerAddress = providerAddress;
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

	public String getStorageLocation() {
		return storageLocation;
	}

	public void setStorageLocation(String storageLocation) {
		this.storageLocation = storageLocation;
	}

	public String getRequesterName() {
		return requesterName;
	}

	public void setRequesterName(String requesterName) {
		this.requesterName = requesterName;
	}

	public String getApproverName() {
		return approverName;
	}

	public void setApproverName(String approverName) {
		this.approverName = approverName;
	}

	public String getIncidentDescription() {
		return incidentDescription;
	}

	public void setIncidentDescription(String incidentDescription) {
		this.incidentDescription = incidentDescription;
	}

	public String getAssetItemCode() {
		return assetItemCode;
	}

	public void setAssetItemCode(String assetItemCode) {
		this.assetItemCode = assetItemCode;
	}

	public String getImageUrl() {
		return imageUrl;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public Long getAssetItemId() {
		return assetItemId;
	}

	public void setAssetItemId(Long assetItemId) {
		this.assetItemId = assetItemId;
	}

	public Long getScheduleId() {
		return scheduleId;
	}

	public void setScheduleId(Long scheduleId) {
		this.scheduleId = scheduleId;
	}

	public String getScheduleTitle() {
		return scheduleTitle;
	}

	public void setScheduleTitle(String scheduleTitle) {
		this.scheduleTitle = scheduleTitle;
	}

	public LocalDate getScheduledDate() {
		return scheduledDate;
	}

	public void setScheduledDate(LocalDate scheduledDate) {
		this.scheduledDate = scheduledDate;
	}

	public String getRepairOutcome() {
		return repairOutcome;
	}

	public void setRepairOutcome(String repairOutcome) {
		this.repairOutcome = repairOutcome;
	}
}
