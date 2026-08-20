package fpt.swp391.labtoolequip.auth;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Collections;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

public final class Authorization {
	private static final Map<String, Set<Permission>> ROLE_PERMISSIONS = Map.of("ADMIN",
			permissions(Permission.DASHBOARD_ADMIN, Permission.USER_MANAGE, Permission.INTERN_LIST_VIEW,
					Permission.INTERN_LIST_REVIEW, Permission.PASSWORD_RESET_REVIEW, Permission.PASSWORD_RESET_ISSUE,
					Permission.PASSWORD_CHANGE),
			"MENTOR",
			permissions(Permission.DASHBOARD_MENTOR, Permission.INTERN_LIST_VIEW, Permission.INTERN_LIST_EDIT,
					Permission.ASSET_VIEW, Permission.ASSET_USAGE_VIEW, Permission.INCIDENT_VIEW, Permission.INCIDENT_REPORT,
					Permission.MAINTENANCE_VIEW,
					Permission.MAINTENANCE_REQUEST, Permission.DISPOSAL_VIEW, Permission.DISPOSAL_REQUEST,
					Permission.PASSWORD_RESET_REQUEST, Permission.PASSWORD_CHANGE),
			"LAB_MANAGER",
			permissions(Permission.DASHBOARD_LAB_MANAGER, Permission.INTERN_LIST_VIEW, Permission.ASSET_VIEW,
					Permission.ASSET_MANAGE, Permission.ASSET_USAGE_VIEW, Permission.INCIDENT_VIEW, Permission.INCIDENT_REVIEW,
					Permission.MAINTENANCE_VIEW,
					Permission.MAINTENANCE_PROCESS, Permission.DISPOSAL_VIEW, Permission.DISPOSAL_REVIEW,
					Permission.DISPOSAL_COMPLETE, Permission.PASSWORD_RESET_REQUEST, Permission.PASSWORD_CHANGE),
			"INTERN", permissions(Permission.DASHBOARD_INTERN, Permission.ASSET_VIEW, Permission.ASSET_USAGE_VIEW,
					Permission.ASSET_USAGE_BORROW, Permission.ASSET_USAGE_RETURN));

	private Authorization() {
	}

	public static boolean has(String role, Permission permission) {
		return ROLE_PERMISSIONS.getOrDefault(role, Set.of()).contains(permission);
	}

	public static boolean has(HttpServletRequest request, Permission permission) {
		return has(AuthSession.role(request), permission);
	}

	public static PermissionView view(String role) {
		return new PermissionView(role);
	}

	private static Set<Permission> permissions(Permission first, Permission... rest) {
		EnumSet<Permission> permissions = EnumSet.of(first, rest);
		return Collections.unmodifiableSet(permissions);
	}

	public static final class PermissionView {
		private final String role;

		private PermissionView(String role) {
			this.role = role;
		}

		public boolean allows(String permission) {
			try {
				return has(role, Permission.valueOf(permission));
			} catch (IllegalArgumentException exception) {
				return false;
			}
		}
	}
}
