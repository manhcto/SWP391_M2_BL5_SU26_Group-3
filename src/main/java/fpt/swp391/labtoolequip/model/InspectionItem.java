package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class InspectionItem {
	private Long inspectionItemId;
	private Long inspectionId;
	private Long assetId;
	private Integer expectedQuantity;
	private Integer actualQuantity;
	private String expectedCondition;
	private String actualCondition;
	private String discrepancyType;
	private String discrepancyNote;
	private LocalDateTime createdAt;
	private String assetCode;
	private String assetName;

	public InspectionItem() {
	}

	public InspectionItem(Long inspectionItemId, Long inspectionId, Long assetId, Integer expectedQuantity,
			Integer actualQuantity, String expectedCondition, String actualCondition, String discrepancyType,
			String discrepancyNote, LocalDateTime createdAt) {
		this.inspectionItemId = inspectionItemId;
		this.inspectionId = inspectionId;
		this.assetId = assetId;
		this.expectedQuantity = expectedQuantity;
		this.actualQuantity = actualQuantity;
		this.expectedCondition = expectedCondition;
		this.actualCondition = actualCondition;
		this.discrepancyType = discrepancyType;
		this.discrepancyNote = discrepancyNote;
		this.createdAt = createdAt;
	}

	public Long getInspectionItemId() {
		return inspectionItemId;
	}

	public void setInspectionItemId(Long inspectionItemId) {
		this.inspectionItemId = inspectionItemId;
	}

	public Long getInspectionId() {
		return inspectionId;
	}

	public void setInspectionId(Long inspectionId) {
		this.inspectionId = inspectionId;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public Integer getExpectedQuantity() {
		return expectedQuantity;
	}

	public void setExpectedQuantity(Integer expectedQuantity) {
		this.expectedQuantity = expectedQuantity;
	}

	public Integer getActualQuantity() {
		return actualQuantity;
	}

	public void setActualQuantity(Integer actualQuantity) {
		this.actualQuantity = actualQuantity;
	}

	public String getExpectedCondition() {
		return expectedCondition;
	}

	public void setExpectedCondition(String expectedCondition) {
		this.expectedCondition = expectedCondition;
	}

	public String getActualCondition() {
		return actualCondition;
	}

	public void setActualCondition(String actualCondition) {
		this.actualCondition = actualCondition;
	}

	public String getDiscrepancyType() {
		return discrepancyType;
	}

	public void setDiscrepancyType(String discrepancyType) {
		this.discrepancyType = discrepancyType;
	}

	public String getDiscrepancyNote() {
		return discrepancyNote;
	}

	public void setDiscrepancyNote(String discrepancyNote) {
		this.discrepancyNote = discrepancyNote;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
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

	public boolean isAbnormal() {
		if (discrepancyType != null && !discrepancyType.isBlank()) {
			return true;
		}
		if (expectedQuantity != null && actualQuantity != null && !expectedQuantity.equals(actualQuantity)) {
			return true;
		}
		return expectedCondition != null && actualCondition != null && !expectedCondition.equals(actualCondition);
	}
}
