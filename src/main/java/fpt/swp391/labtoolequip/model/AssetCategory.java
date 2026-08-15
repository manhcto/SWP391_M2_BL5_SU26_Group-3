package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class AssetCategory {
	private Long categoryId;
	private String categoryName;
	private String description;
	private String status;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public AssetCategory() {
	}

	public AssetCategory(Long categoryId, String categoryName, String description, String status,
			LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.categoryId = categoryId;
		this.categoryName = categoryName;
		this.description = description;
		this.status = status;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getCategoryId() {
		return categoryId;
	}

	public void setCategoryId(Long categoryId) {
		this.categoryId = categoryId;
	}

	public String getCategoryName() {
		return categoryName;
	}

	public void setCategoryName(String categoryName) {
		this.categoryName = categoryName;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
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
