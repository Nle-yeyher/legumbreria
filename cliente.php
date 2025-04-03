<?php
session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);
include("db.php");

// Verificar conexión con la base de datos
if (!$conn) {
    die("❌ Error de conexión a la base de datos: " . mysqli_connect_error());
}

// Verificar si el usuario ha iniciado sesión y es Cliente
if (!isset($_SESSION['rol']) || $_SESSION['rol'] !== 'Cliente') {
    header("Location: login.php");
    exit();
}

if (!isset($_SESSION['id_usuario'])) {
    die("❌ Error: No se encontró el ID del usuario en la sesión.");
}

$id_usuario = $_SESSION['id_usuario']; // Cambiamos id_cliente por id_usuario
$mensaje = ""; // Variable para mostrar mensajes

// Agregar producto al carrito
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['agregar_carrito'])) {
    if (!isset($_POST['id_producto']) || !isset($_POST['cantidad'])) {
        $mensaje = "⚠️ Error: Falta información del producto.";
    } else {
        $id_producto = intval($_POST['id_producto']);
        $cantidad = intval($_POST['cantidad']);

        // Verificar si el producto existe y tiene suficiente stock
        $stmt = $conn->prepare("SELECT cantidad FROM productos WHERE id_producto = ?");
        $stmt->bind_param("i", $id_producto);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $producto = $result->fetch_assoc();
            if ($producto['cantidad'] >= $cantidad) {
                // Insertar en el carrito usando consulta preparada
                $stmt = $conn->prepare("INSERT INTO carrito (id_usuario, id_producto, cantidad) VALUES (?, ?, ?)");
                $stmt->bind_param("iii", $id_usuario, $id_producto, $cantidad);
                
                if ($stmt->execute()) {
                    $mensaje = "✅ Producto agregado al carrito correctamente.";
                } else {
                    $mensaje = "❌ Error al agregar al carrito: " . $conn->error;
                }
            } else {
                $mensaje = "⚠️ Error: No hay suficiente stock disponible.";
            }
        } else {
            $mensaje = "⚠️ Error: Producto no encontrado.";
        }
        $stmt->close();
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel del Cliente</title>
    <link rel="stylesheet" href="compra.css">
</head>
<body>
    <div class="container">
        <h2>Bienvenido, <?php echo htmlspecialchars($_SESSION['usuario']); ?>!</h2>

        <!-- Mostrar mensaje -->
        <?php if ($mensaje): ?>
            <p class="mensaje"><?php echo $mensaje; ?></p>
        <?php endif; ?>

        <!-- Ver Productos -->
        <h3>Productos Disponibles</h3>
        <table>
            <tr>
                <th>Producto</th>
                <th>Precio</th>
                <th>Stock</th>
                <th>Acción</th>
            </tr>
            <?php
            $result = $conn->query("SELECT * FROM productos");
            while ($row = $result->fetch_assoc()) {
                echo "<tr>
                        <td>{$row['nombre']}</td>
                        <td>\${$row['precio']}</td>
                        <td>{$row['cantidad']}</td>
                        <td>
                            <form method='POST'>
                                <input type='hidden' name='id_producto' value='{$row['id_producto']}'>
                                <input type='number' name='cantidad' min='1' max='{$row['cantidad']}' required>
                                <button type='submit' name='agregar_carrito'>Agregar al Carrito</button>
                            </form>
                        </td>
                    </tr>";
            }
            ?>
        </table>

        <!-- Ver Carrito -->
        <h3>Mi Carrito</h3>
        <table>
            <tr>
                <th>ID</th>
                <th>Producto</th>
                <th>Cantidad</th>
                <th>Total</th>
            </tr>
            <?php
            $query = "
                SELECT carrito.id_carrito, productos.nombre AS producto, carrito.cantidad, (productos.precio * carrito.cantidad) AS total 
                FROM carrito
                JOIN productos ON carrito.id_producto = productos.id_producto
                WHERE carrito.id_usuario = '$id_usuario'
            ";
            $result = $conn->query($query);
            
            if ($result->num_rows > 0) {
                while ($row = $result->fetch_assoc()) {
                    echo "<tr>
                            <td>{$row['id_carrito']}</td>
                            <td>{$row['producto']}</td>
                            <td>{$row['cantidad']}</td>
                            <td>\${$row['total']}</td>
                          </tr>";
                }
            } else {
                echo "<tr><td colspan='4'>🛒 No tienes productos en el carrito.</td></tr>";
            }
            ?>
        </table>

        <a href="logout.php" class="link-button">Cerrar Sesión</a>
    </div>

    <style>
        .container {
            width: 80%;
            margin: auto;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid black;
            padding: 10px;
            text-align: center;
        }
        .mensaje {
            font-weight: bold;
            color: red;
        }
        .link-button {
            display: inline-block;
            padding: 10px 20px;
            background-color: blue;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
    </style>

</body>
</html>
