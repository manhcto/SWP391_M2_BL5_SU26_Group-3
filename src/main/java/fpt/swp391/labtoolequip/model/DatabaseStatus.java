package fpt.swp391.labtoolequip.model;

/** Safe database health information for the system status view. */
public final class DatabaseStatus {
	private final boolean connected;
	private final String message;

	public DatabaseStatus(boolean connected, String message) {
		this.connected = connected;
		this.message = message;
	}

	public boolean isConnected() {
		return connected;
	}

	public String getMessage() {
		return message;
	}
}
