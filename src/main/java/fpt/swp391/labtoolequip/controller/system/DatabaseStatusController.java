package fpt.swp391.labtoolequip.controller.system;

import fpt.swp391.labtoolequip.model.DatabaseStatus;
import fpt.swp391.labtoolequip.service.DatabaseHealthService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/system/database-status")
public class DatabaseStatusController extends HttpServlet {
	private final DatabaseHealthService service = new DatabaseHealthService();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			request.setAttribute("databaseStatus", service.check());
		} catch (SQLException exception) {
			getServletContext().log("Database health check failed", exception);
			request.setAttribute("databaseStatus",
					new DatabaseStatus(false, "Kết nối database thất bại. Hãy kiểm tra SQL Server và cấu hình .env."));
		}
		request.getRequestDispatcher("/WEB-INF/views/system/database-status.jsp").forward(request, response);
	}
}
