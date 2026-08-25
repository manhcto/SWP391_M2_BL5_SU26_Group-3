package fpt.swp391.labtoolequip.model;

import java.time.LocalDateTime;

public class AssetItemLifecycleEvent {
	private final LocalDateTime occurredAt;
	private final String eventType;
	private final String eventLabel;
	private final String detail;
	private final String status;
	private final String actorName;
	private final String referenceType;
	private final long referenceId;
	private final String scope;
	private final String result;

	public AssetItemLifecycleEvent(LocalDateTime occurredAt, String eventType, String eventLabel, String detail,
			String status, String actorName, String referenceType, long referenceId, String scope) {
		this(occurredAt, eventType, eventLabel, detail, status, actorName, referenceType, referenceId, scope, null);
	}

	public AssetItemLifecycleEvent(LocalDateTime occurredAt, String eventType, String eventLabel, String detail,
			String status, String actorName, String referenceType, long referenceId, String scope, String result) {
		this.occurredAt = occurredAt;
		this.eventType = eventType;
		this.eventLabel = eventLabel;
		this.detail = detail;
		this.status = status;
		this.actorName = actorName;
		this.referenceType = referenceType;
		this.referenceId = referenceId;
		this.scope = scope;
		this.result = result;
	}

	public LocalDateTime getOccurredAt() {
		return occurredAt;
	}

	public String getEventType() {
		return eventType;
	}

	public String getEventLabel() {
		return eventLabel;
	}

	public String getDetail() {
		return detail;
	}

	public String getStatus() {
		return status;
	}

	public String getActorName() {
		return actorName;
	}

	public String getReferenceType() {
		return referenceType;
	}

	public long getReferenceId() {
		return referenceId;
	}

	public String getScope() {
		return scope;
	}

	public String getResult() {
		return result;
	}
}
