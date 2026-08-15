package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class Asset {
	private Long assetId;
	private String assetCode;
	private String assetName;
	private Long categoryId;
	private String trackingMode;
	private String serialNumber;
	private Integer totalQuantity;
	private String condition;
	private String status;
	private Boolean borrowable;
	private String storageLocation;
	private String description;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public Asset() {
	}

	public Asset(Long assetId, String assetCode, String assetName, Long categoryId, String trackingMode,
			String serialNumber, Integer totalQuantity, String condition, String status, Boolean borrowable,
			String storageLocation, String description, LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.assetId = assetId;
		this.assetCode = assetCode;
		this.assetName = assetName;
		this.categoryId = categoryId;
		this.trackingMode = trackingMode;
		this.serialNumber = serialNumber;
		this.totalQuantity = totalQuantity;
		this.condition = condition;
		this.status = status;
		this.borrowable = borrowable;
		this.storageLocation = storageLocation;
		this.description = description;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
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

	public Long getCategoryId() {
		return categoryId;
	}

	public void setCategoryId(Long categoryId) {
		this.categoryId = categoryId;
	}

	public String getTrackingMode() {
		return trackingMode;
	}

	public void setTrackingMode(String trackingMode) {
		this.trackingMode = trackingMode;
	}

	public String getSerialNumber() {
		return serialNumber;
	}

	public void setSerialNumber(String serialNumber) {
		this.serialNumber = serialNumber;
	}

	public Integer getTotalQuantity() {
		return totalQuantity;
	}

	public void setTotalQuantity(Integer totalQuantity) {
		this.totalQuantity = totalQuantity;
	}

	public String getCondition() {
		return condition;
	}

	public void setCondition(String condition) {
		this.condition = condition;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Boolean getBorrowable() {
		return borrowable;
	}

	public void setBorrowable(Boolean borrowable) {
		this.borrowable = borrowable;
	}

	public String getStorageLocation() {
		return storageLocation;
	}

	public void setStorageLocation(String storageLocation) {
		this.storageLocation = storageLocation;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
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
