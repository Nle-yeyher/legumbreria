<?php
session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);

include("db.php");

// Verificar si el usuario es proveedor
if (!isset($_SESSION['rol']) || $_SESSION['rol'] !== 'Proveedor') {
    header("Location: login.php");
    exit();
}

// Actualizar el stock si se envía el formulario
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['actualizar_stock'])) {
    if (isset($_POST['id_producto']) && isset($_POST['nuevo_stock'])) {
        $id_producto = intval($_POST['id_producto']);
        $nuevo_stock = intval($_POST['nuevo_stock']);

        // Validar que el nuevo stock sea un número válido
        if ($nuevo_stock >= 0) {
            $query = "UPDATE productos SET cantidad = ? WHERE id_producto = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ii", $nuevo_stock, $id_producto);

            if ($stmt->execute()) {
                echo "✅ Stock actualizado correctamente.";
            } else {
                echo "❌ Error al actualizar stock: " . $conn->error;
            }
            $stmt->close();
        } else {
            echo "⚠️ Ingrese un valor válido para el stock.";
        }
    } else {
        echo "⚠️ Datos incompletos.";
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel del Proveedor</title>
    <link rel="stylesheet" href="prove.css">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <div class="container">
        <h2>Gestión de Productos</h2>

        <table border="1">
            <tr>
                <th>Producto</th>
                <th>Stock Actual</th>
                <th>Nuevo Stock</th>
                <th>Actualizar</th>
            </tr>
            <?php
            // Obtener todos los productos sin filtrar el stock
            $result = $conn->query("SELECT id_producto, nombre, cantidad FROM productos");

            while ($row = $result->fetch_assoc()) {
                $stock_actual = $row['cantidad'] ?? 0; // Si es NULL, lo pone en 0
                echo "<tr>
                        <td>{$row['nombre']}</td>
                        <td id='stock_{$row['id_producto']}'>{$stock_actual}</td>
                        <td><input type='number' id='nuevo_stock_{$row['id_producto']}' value='{$stock_actual}' min='0'></td>
                        <td><button onclick='actualizarStock({$row['id_producto']})'>Actualizar</button></td>
                    </tr>";
            }
            ?>
        </table>

        <a href="logout.php" class="link-button">Cerrar Sesión</a>
    </div>

    <script>
        function actualizarStock(idProducto) {
            let nuevoStock = document.getElementById('nuevo_stock_' + idProducto).value;

            if (nuevoStock < 0 || isNaN(nuevoStock)) {
                alert("⚠️ Ingrese un stock válido.");
                return;
            }

            $.post("actualizar_stock.php", { id_producto: idProducto, nuevo_stock: nuevoStock }, function(data) {
                document.getElementById('stock_' + idProducto).innerText = nuevoStock;
                alert(data);
            });
        }
    </script>
</body>
</html>
