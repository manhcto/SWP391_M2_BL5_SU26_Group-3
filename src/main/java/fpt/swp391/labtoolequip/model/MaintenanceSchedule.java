package fpt.swp391.labtoolequip.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

public class MaintenanceSchedule {
	private Long scheduleId;
	private String title;
	private Long assetId;
	private String itemCode;
	private LocalDate scheduledDate;
	private Long estimatedCost;
	private String providerName;
	private String providerPhone;
	private String note;
	private String status; // PENDING, COMPLETED, CANCELLED
	private Long createdBy;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	// Joined display fields
	private String assetCode;
	private String assetName;
	private String storageLocation;
	private String creatorName;

	public MaintenanceSchedule() {
	}

	// Helper methods for alerts
	public boolean isOverdue() {
		return "PENDING".equalsIgnoreCase(status) && scheduledDate != null && scheduledDate.isBefore(LocalDate.now());
	}

	public boolean isDueSoon() {
		if (!"PENDING".equalsIgnoreCase(status) || scheduledDate == null || isOverdue()) {
			return false;
		}
		return !scheduledDate.isAfter(LocalDate.now().plusDays(7));
	}

	public long getDaysDiff() {
		if (scheduledDate == null) {
			return 0;
		}
		return ChronoUnit.DAYS.between(LocalDate.now(), scheduledDate);
	}

	public Long getScheduleId() {
		return scheduleId;
	}

	public void setScheduleId(Long scheduleId) {
		this.scheduleId = scheduleId;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public LocalDate getScheduledDate() {
		return scheduledDate;
	}

	public void setScheduledDate(LocalDate scheduledDate) {
		this.scheduledDate = scheduledDate;
	}

	public Long getEstimatedCost() {
		return estimatedCost;
	}

	public void setEstimatedCost(Long estimatedCost) {
		this.estimatedCost = estimatedCost;
	}

	public String getProviderName() {
		return providerName;
	}

	public void setProviderName(String providerName) {
		this.providerName = providerName;
	}

	public String getProviderPhone() {
		return providerPhone;
	}

	public void setProviderPhone(String providerPhone) {
		this.providerPhone = providerPhone;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
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

	public String getStorageLocation() {
		return storageLocation;
	}

	public void setStorageLocation(String storageLocation) {
		this.storageLocation = storageLocation;
	}

	public String getItemCode() {
		return itemCode;
	}

	public void setItemCode(String itemCode) {
		this.itemCode = itemCode;
	}

	public String getCreatorName() {
		return creatorName;
	}

	public void setCreatorName(String creatorName) {
		this.creatorName = creatorName;
	}
}
