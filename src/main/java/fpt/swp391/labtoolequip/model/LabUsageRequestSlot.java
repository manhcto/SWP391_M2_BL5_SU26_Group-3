package fpt.swp391.labtoolequip.model;

import java.time.LocalTime;

public class LabUsageRequestSlot {
	private Long requestId;
	private int dayOfWeek;
	private int slotId;
	private LocalTime startTime;
	private LocalTime endTime;

	public Long getRequestId() {
		return requestId;
	}

	public void setRequestId(Long requestId) {
		this.requestId = requestId;
	}

	public int getDayOfWeek() {
		return dayOfWeek;
	}

	public void setDayOfWeek(int dayOfWeek) {
		this.dayOfWeek = dayOfWeek;
	}

	public int getSlotId() {
		return slotId;
	}

	public void setSlotId(int slotId) {
		this.slotId = slotId;
	}

	public LocalTime getStartTime() {
		return startTime;
	}

	public void setStartTime(LocalTime startTime) {
		this.startTime = startTime;
	}

	public LocalTime getEndTime() {
		return endTime;
	}

	public void setEndTime(LocalTime endTime) {
		this.endTime = endTime;
	}

	public String getDayLabel() {
		return "Thứ " + dayOfWeek;
	}

	public String getTimeLabel() {
		return startTime + "–" + endTime;
	}

	public String getKey() {
		return dayOfWeek + "-" + slotId;
	}
}
