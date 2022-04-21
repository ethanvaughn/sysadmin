import java.util.*;

public interface ServiceCheck {
	public String getPluginOutput();
	public int getPluginStatusCode();
	public void run();
}
