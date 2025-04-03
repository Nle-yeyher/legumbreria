<?php
include("db.php");

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $id_producto = $_POST['id_producto'];
    $nuevo_stock = $_POST['nuevo_stock'];

    $query = "UPDATE productos SET cantidad = '$nuevo_stock' WHERE id_producto = '$id_producto'";
    if ($conn->query($query)) {
        echo "Stock actualizado";
    } else {
        echo "Error al actualizar";
    }
}
?>
