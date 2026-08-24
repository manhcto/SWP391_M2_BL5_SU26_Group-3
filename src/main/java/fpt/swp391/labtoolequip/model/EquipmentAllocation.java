package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class EquipmentAllocation {
	private Long allocationId;
	private Long allocationRequestId;
	private Long assetItemId;
	private String status;
	private String activityName;
	private String targetName;
	private String assetName;
	private String itemCode;
	private String condition;
	private LocalDateTime handedOverAt;
	private LocalDateTime receivedAt;
	private LocalDateTime recoveredAt;

	public Long getAllocationId() { return allocationId; }
	public void setAllocationId(Long allocationId) { this.allocationId = allocationId; }
	public Long getAllocationRequestId() { return allocationRequestId; }
	public void setAllocationRequestId(Long allocationRequestId) { this.allocationRequestId = allocationRequestId; }
	public Long getAssetItemId() { return assetItemId; }
	public void setAssetItemId(Long assetItemId) { this.assetItemId = assetItemId; }
	public String getStatus() { return status; }
	public void setStatus(String status) { this.status = status; }
	public String getActivityName() { return activityName; }
	public void setActivityName(String activityName) { this.activityName = activityName; }
	public String getTargetName() { return targetName; }
	public void setTargetName(String targetName) { this.targetName = targetName; }
	public String getAssetName() { return assetName; }
	public void setAssetName(String assetName) { this.assetName = assetName; }
	public String getItemCode() { return itemCode; }
	public void setItemCode(String itemCode) { this.itemCode = itemCode; }
	public String getCondition() { return condition; }
	public void setCondition(String condition) { this.condition = condition; }
	public LocalDateTime getHandedOverAt() { return handedOverAt; }
	public void setHandedOverAt(LocalDateTime handedOverAt) { this.handedOverAt = handedOverAt; }
	public LocalDateTime getReceivedAt() { return receivedAt; }
	public void setReceivedAt(LocalDateTime receivedAt) { this.receivedAt = receivedAt; }
	public LocalDateTime getRecoveredAt() { return recoveredAt; }
	public void setRecoveredAt(LocalDateTime recoveredAt) { this.recoveredAt = recoveredAt; }
}
