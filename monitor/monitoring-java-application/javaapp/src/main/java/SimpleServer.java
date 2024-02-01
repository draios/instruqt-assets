import static spark.Spark.*;

import java.lang.management.ManagementFactory;
import java.util.ArrayList;
import java.util.List;

import javax.management.*;

public class SimpleServer {

    private static List<byte[]> memoryLeak = new ArrayList<>();

    private static String computeIntensiveTask() {
        double result = 0;
        for (int i = 0; i < 1000000; i++) { // Este número puede ajustarse según la carga que desees simular
            result += Math.sin(i) * Math.cos(i);
        }
        return "Computation completed" + result;
    }

    public static RequestCounter requestCounter = new RequestCounter();

    public static void main(String[] args) throws MalformedObjectNameException, NotCompliantMBeanException,
            InstanceAlreadyExistsException, MBeanRegistrationException {
        // Configura el puerto
        port(8030);

        // Define una ruta para el endpoint raíz que devuelve "Hello, World!"
        get("/", (req, res) -> {
            // Incrementar el contador de peticiones cada vez que este endpoint es accedido
            requestCounter.increment();
            return "Hello, World!";
        });

        // Endpoint que consume CPU
        get("/compute", (req, res) -> {
            long startTime = System.currentTimeMillis();
            while (System.currentTimeMillis() - startTime < 2000) { // 2 segundos
                computeIntensiveTask();
            }
            return "Task completed!";
        });

        get("/register", (req, res) -> {
            // Reserva 10 MB de memoria y los agrega a la lista
            memoryLeak.add(new byte[10 * 1024 * 1024]);
            return "Database Loaded";
        });

        // Registra el MBean para exponer métricas a través de JMX
        registerMBeans();
    }

    private static void registerMBeans() throws MalformedObjectNameException, NotCompliantMBeanException,
            InstanceAlreadyExistsException, MBeanRegistrationException {
        MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();

        // Registra el MBean del contador de peticiones
        ObjectName requestCounterName = new ObjectName("SimpleServer:type=RequestCounter");
        RequestCounterMBean requestCounterMBean = new RequestCounter();
        mbs.registerMBean(requestCounterMBean, requestCounterName);
    }

    // Define la interfaz MBean para el contador de peticiones
    public interface RequestCounterMBean {
        void increment();

        int getCount();
    }

    // Implementa el MBean para el contador de peticiones
    public static class RequestCounter implements RequestCounterMBean {
        private int count = 0;

        @Override
        public void increment() {
            count++;
        }

        @Override
        public int getCount() {
            return count;
        }
    }
}
