package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class Incident {
	private Long incidentId;
	private Long assetId;
	private Long assetItemId;
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
	private String reportedCause;
	private String determinedCause;
	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;
	private String assetCode;
	private String assetName;
	private String assetItemCode;
	private String reporterName;
	private String internCode;
	private String internName;

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

	public Long getAssetItemId() {
		return assetItemId;
	}

	public void setAssetItemId(Long assetItemId) {
		this.assetItemId = assetItemId;
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

	public String getReportedCause() { return reportedCause; }
	public void setReportedCause(String reportedCause) { this.reportedCause = reportedCause; }
	public String getDeterminedCause() { return determinedCause; }
	public void setDeterminedCause(String determinedCause) { this.determinedCause = determinedCause; }

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

	public String getAssetItemCode() {
		return assetItemCode;
	}

	public void setAssetItemCode(String assetItemCode) {
		this.assetItemCode = assetItemCode;
	}

	public String getReporterName() {
		return reporterName;
	}

	public void setReporterName(String reporterName) {
		this.reporterName = reporterName;
	}

	public String getInternCode() {
		return internCode;
	}

	public void setInternCode(String internCode) {
		this.internCode = internCode;
	}

	public String getInternName() {
		return internName;
	}

	public void setInternName(String internName) {
		this.internName = internName;
	}
}
