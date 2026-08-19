package fpt.swp391.labtoolequip.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class AssetItem {
	private Long assetItemId;
	private Long assetId;
	private String assetCode;
	private String assetName;
	private String categoryName;
	private Boolean borrowable;
	private String itemCode;
	private String serialNumber;
	private String imagePath;
	private String condition;
	private String status;
	private String storageLocation;
	private LocalDate purchaseDate;
	private LocalDate warrantyUntil;
	private String note;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public Long getAssetItemId() {
		return assetItemId;
	}
	public void setAssetItemId(Long assetItemId) {
		this.assetItemId = assetItemId;
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
	public String getCategoryName() {
		return categoryName;
	}
	public void setCategoryName(String categoryName) {
		this.categoryName = categoryName;
	}
	public Boolean getBorrowable() {
		return borrowable;
	}
	public void setBorrowable(Boolean borrowable) {
		this.borrowable = borrowable;
	}
	public String getItemCode() {
		return itemCode;
	}
	public void setItemCode(String itemCode) {
		this.itemCode = itemCode;
	}
	public String getSerialNumber() {
		return serialNumber;
	}
	public void setSerialNumber(String serialNumber) {
		this.serialNumber = serialNumber;
	}
	public String getImagePath() {
		return imagePath;
	}
	public void setImagePath(String imagePath) {
		this.imagePath = imagePath;
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
	public String getStorageLocation() {
		return storageLocation;
	}
	public void setStorageLocation(String storageLocation) {
		this.storageLocation = storageLocation;
	}
	public LocalDate getPurchaseDate() {
		return purchaseDate;
	}
	public void setPurchaseDate(LocalDate purchaseDate) {
		this.purchaseDate = purchaseDate;
	}
	public LocalDate getWarrantyUntil() {
		return warrantyUntil;
	}
	public void setWarrantyUntil(LocalDate warrantyUntil) {
		this.warrantyUntil = warrantyUntil;
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
