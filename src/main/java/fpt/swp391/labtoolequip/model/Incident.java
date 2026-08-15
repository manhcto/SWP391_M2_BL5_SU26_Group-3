package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class Incident {
	private Long incidentId;
	private Long assetId;
	private Long assetUsageId;
	private Long inspectionItemId;
	private Long reportedBy;
	private Integer affectedQuantity;
	private String incidentType;
	private String description;
	private String severity;
	private String status;
	private LocalDateTime occurredAt;
	private LocalDateTime reportedAt;
	private String investigationNote;
	private String handlingResult;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	public Incident() {
	}

	public Incident(Long incidentId, Long assetId, Long assetUsageId, Long inspectionItemId, Long reportedBy,
			Integer affectedQuantity, String incidentType, String description, String severity, String status,
			LocalDateTime occurredAt, LocalDateTime reportedAt, String investigationNote, String handlingResult,
			LocalDateTime createdAt, LocalDateTime updatedAt) {
		this.incidentId = incidentId;
		this.assetId = assetId;
		this.assetUsageId = assetUsageId;
		this.inspectionItemId = inspectionItemId;
		this.reportedBy = reportedBy;
		this.affectedQuantity = affectedQuantity;
		this.incidentType = incidentType;
		this.description = description;
		this.severity = severity;
		this.status = status;
		this.occurredAt = occurredAt;
		this.reportedAt = reportedAt;
		this.investigationNote = investigationNote;
		this.handlingResult = handlingResult;
		this.createdAt = createdAt;
		this.updatedAt = updatedAt;
	}

	public Long getIncidentId() {
		return incidentId;
	}

	public void setIncidentId(Long incidentId) {
		this.incidentId = incidentId;
	}

	public Long getAssetId() {
		return assetId;
	}

	public void setAssetId(Long assetId) {
		this.assetId = assetId;
	}

	public Long getAssetUsageId() {
		return assetUsageId;
	}

	public void setAssetUsageId(Long assetUsageId) {
		this.assetUsageId = assetUsageId;
	}

	public Long getInspectionItemId() {
		return inspectionItemId;
	}

	public void setInspectionItemId(Long inspectionItemId) {
		this.inspectionItemId = inspectionItemId;
	}

	public Long getReportedBy() {
		return reportedBy;
	}

	public void setReportedBy(Long reportedBy) {
		this.reportedBy = reportedBy;
	}

	public Integer getAffectedQuantity() {
		return affectedQuantity;
	}

	public void setAffectedQuantity(Integer affectedQuantity) {
		this.affectedQuantity = affectedQuantity;
	}

	public String getIncidentType() {
		return incidentType;
	}

	public void setIncidentType(String incidentType) {
		this.incidentType = incidentType;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getSeverity() {
		return severity;
	}

	public void setSeverity(String severity) {
		this.severity = severity;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public LocalDateTime getOccurredAt() {
		return occurredAt;
	}

	public void setOccurredAt(LocalDateTime occurredAt) {
		this.occurredAt = occurredAt;
	}

	public LocalDateTime getReportedAt() {
		return reportedAt;
	}

	public void setReportedAt(LocalDateTime reportedAt) {
		this.reportedAt = reportedAt;
	}

	public String getInvestigationNote() {
		return investigationNote;
	}

	public void setInvestigationNote(String investigationNote) {
		this.investigationNote = investigationNote;
	}

	public String getHandlingResult() {
		return handlingResult;
	}

	public void setHandlingResult(String handlingResult) {
		this.handlingResult = handlingResult;
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
