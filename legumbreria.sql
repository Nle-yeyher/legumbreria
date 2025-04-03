-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 03-04-2025 a las 04:24:16
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `legumbreria`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_salario_empleado` (IN `p_id_empleado` INT, IN `p_nuevo_salario` DECIMAL(10,2))   BEGIN
    UPDATE empleados
    SET salario = p_nuevo_salario
    WHERE id_empleado = p_id_empleado;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_stock` (IN `p_id_producto` INT, IN `p_cantidad` INT)   BEGIN
    UPDATE productos
    SET stock = stock - p_cantidad
    WHERE id_producto = p_id_producto;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `controlar_intentos_login` (IN `p_usuario` VARCHAR(100))   BEGIN
    DECLARE intentos INT DEFAULT 0;

    -- Verificar si el usuario existe y obtener sus intentos fallidos
    SELECT intentos_fallidos INTO intentos 
    FROM usuarios 
    WHERE usuario = p_usuario 
    LIMIT 1;

    -- Si el usuario no existe, detener la ejecución
    IF intentos IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;

    -- Si el usuario ha fallado 3 veces, bloquearlo
    IF intentos >= 4 THEN
        UPDATE usuarios 
        SET bloqueado = 1 
        WHERE usuario = p_usuario;

        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Usuario bloqueado por intentos fallidos';
    ELSE
        -- Aumentar el contador de intentos fallidos
        UPDATE usuarios 
        SET intentos_fallidos = intentos + 1 
        WHERE usuario = p_usuario;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `eliminar_empleado` (IN `p_id_empleado` INT)   BEGIN
    DELETE FROM empleados WHERE id_empleado = p_id_empleado;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `listar_ventas` ()   BEGIN
    SELECT * FROM detalles_ventas;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `obtener_stock` (IN `p_id_producto` INT)   BEGIN
    SELECT stock FROM productos WHERE id_producto = p_id_producto;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `promedio_precio_producto` (IN `p_id_producto` INT)   BEGIN
    SELECT AVG(precio_unitario) AS promedio_precio
    FROM detalles_ventas
    WHERE id_producto = p_id_producto;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_compra` (IN `p_id_producto` INT, IN `p_cantidad` INT, IN `p_precio_compra` DECIMAL(10,2))   BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    SET v_subtotal = p_cantidad * p_precio_compra;
    
    INSERT INTO detalles_compras (id_producto, cantidad, precio_compra, subtotal)
    VALUES (p_id_producto, p_cantidad, p_precio_compra, v_subtotal);
    
    -- Actualizar el stock del producto
    UPDATE productos
    SET stock = stock + p_cantidad
    WHERE id_producto = p_id_producto;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_empleado` (IN `p_nombre` VARCHAR(100), IN `p_apellido` VARCHAR(100), IN `p_cargo` VARCHAR(50), IN `p_salario` DECIMAL(10,2))   BEGIN
    INSERT INTO empleados (nombre, apellido, cargo, salario)
    VALUES (p_nombre, p_apellido, p_cargo, p_salario);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_usuario` (IN `p_usuario` VARCHAR(100), IN `p_password` VARCHAR(255), IN `p_rol` VARCHAR(50))   BEGIN
    INSERT INTO usuarios (usuario, password_hash, rol)
    VALUES (p_usuario, SHA2(p_password, 256), p_rol);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_venta` (IN `p_id_producto` INT, IN `p_cantidad` INT, IN `p_precio_unitario` DECIMAL(10,2))   BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    SET v_subtotal = p_cantidad * p_precio_unitario;
    
    INSERT INTO detalles_ventas (id_producto, cantidad, precio_unitario, subtotal)
    VALUES (p_id_producto, p_cantidad, p_precio_unitario, v_subtotal);
    
    -- Llamar al procedimiento para actualizar el stock
    CALL actualizar_stock(p_id_producto, p_cantidad);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `total_productos_stock` ()   BEGIN
    SELECT SUM(stock) AS total_stock FROM productos;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `estado_producto` (`id_producto` INT) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE stock_actual INT;
    
    SELECT stock INTO stock_actual
    FROM productos
    WHERE productos.id_producto = id_producto;
    
    IF stock_actual > 10 THEN
        RETURN 'Disponible';
    ELSEIF stock_actual BETWEEN 1 AND 10 THEN
        RETURN 'Pocas Unidades';
    ELSE
        RETURN 'Agotado';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `precio_promedio_productos` () RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE promedio DECIMAL(10,2);
    
    SELECT AVG(precio) INTO promedio FROM productos;
    
    RETURN IFNULL(promedio, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_compras_cliente` (`cliente_id` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT SUM(total) INTO total FROM ventas WHERE id_cliente = cliente_id;
    
    RETURN IFNULL(total, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_compras_proveedor` (`id_proveedor` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT SUM(total) INTO total
    FROM registro_compras
    WHERE registro_compras.id_proveedor = id_proveedor;
    
    RETURN IFNULL(total, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_gasto_cliente` (`id_cliente` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT SUM(total) INTO total
    FROM ventas
    WHERE ventas.id_cliente = id_cliente;
    
    RETURN IFNULL(total, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_stock` () RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE total INT;
    
    SELECT SUM(stock) INTO total FROM productos;
    
    RETURN IFNULL(total, 0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `carrito`
--

CREATE TABLE `carrito` (
  `id_carrito` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL DEFAULT 1,
  `fecha_agregado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `carrito`
--

INSERT INTO `carrito` (`id_carrito`, `id_usuario`, `id_producto`, `cantidad`, `fecha_agregado`) VALUES
(2, 1, 4, 1, '2025-04-03 01:45:52'),
(3, 1, 7, 1, '2025-04-03 01:46:14'),
(4, 1, 7, 1, '2025-04-03 01:48:58'),
(5, 1, 4, 1, '2025-04-03 01:49:03'),
(6, 1, 7, 1, '2025-04-03 01:49:11'),
(7, 1, 7, 1, '2025-04-03 01:50:16');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `nombre`, `apellido`, `telefono`, `direccion`, `correo`) VALUES
(1, 'Juan', 'Pérez', '123456789', 'Calle 1 #23-45', 'juan.perez@email.com'),
(2, 'María', 'Gómez', '987654321', 'Carrera 2 #34-56', 'maria.gomez@email.com'),
(3, 'Carlos', 'López', '321654987', 'Avenida 3 #12-34', 'carlos.lopez@email.com'),
(4, 'Sofía', 'Díaz', '876543210', 'Calle 4 #10-11', 'sofia.diaz@email.com'),
(5, 'Ricardo', 'Torres', '765432109', 'Carrera 5 #22-33', 'ricardo.torres@email.com'),
(6, 'Laura', 'Martínez', '654321098', 'Diagonal 6 #44-55', 'laura.martinez@email.com'),
(7, 'Andrés', 'Hernández', '543210987', 'Calle 7 #66-77', 'andres.hernandez@email.com'),
(8, 'Valeria', 'Fernández', '432109876', 'Carrera 8 #88-99', 'valeria.fernandez@email.com'),
(9, 'Miguel', 'Ortega', '321098765', 'Avenida 9 #12-23', 'miguel.ortega@email.com'),
(10, 'Paula', 'Castro', '210987654', 'Transversal 10 #34-45', 'paula.castro@email.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_compras`
--

CREATE TABLE `detalles_compras` (
  `id_detalle` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_compra` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_compras`
--

INSERT INTO `detalles_compras` (`id_detalle`, `id_compra`, `id_producto`, `cantidad`, `precio_compra`, `subtotal`) VALUES
(1, 1, 1, 10, 3000.00, 30000.00),
(2, 2, 3, 5, 5000.00, 25000.00),
(3, 3, 5, 7, 7000.00, 35000.00),
(4, 4, 7, 8, 10000.00, 40000.00),
(5, 5, 9, 6, 5000.00, 28000.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_ventas`
--

CREATE TABLE `detalles_ventas` (
  `id_detalle` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalles_ventas`
--

INSERT INTO `detalles_ventas` (`id_detalle`, `id_venta`, `id_producto`, `cantidad`, `precio_unitario`, `subtotal`) VALUES
(1, 1, 1, 2, 5000.00, 10000.00),
(2, 1, 2, 1, 5000.00, 5000.00),
(3, 2, 3, 2, 5500.00, 11000.00),
(4, 3, 4, 3, 5000.00, 15000.00),
(5, 4, 5, 1, 7000.00, 7000.00),
(6, 6, 1, 3, 5000.00, 15000.00),
(7, 6, 3, 2, 5500.00, 11000.00),
(8, 6, 1, 3, 5000.00, 15000.00),
(9, 6, 3, 2, 5500.00, 11000.00);

--
-- Disparadores `detalles_ventas`
--
DELIMITER $$
CREATE TRIGGER `actualizar_stock_despues_venta` AFTER INSERT ON `detalles_ventas` FOR EACH ROW BEGIN
    UPDATE productos 
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `evitar_venta_sin_stock` BEFORE INSERT ON `detalles_ventas` FOR EACH ROW BEGIN
    DECLARE stock_actual INT;
    
    -- Obtener stock actual del producto
    SELECT stock INTO stock_actual
    FROM productos
    WHERE id_producto = NEW.id_producto;
    
    -- Si el stock es insuficiente, genera un error
    IF stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay suficiente stock para esta venta';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `reducir_stock_venta` AFTER INSERT ON `detalles_ventas` FOR EACH ROW BEGIN
    UPDATE productos
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `verificar_stock_antes_venta` BEFORE INSERT ON `detalles_ventas` FOR EACH ROW BEGIN
    DECLARE stock_actual INT;
    
    -- Obtener el stock del producto
    SELECT stock INTO stock_actual FROM productos WHERE id_producto = NEW.id_producto;
    
    -- Verificar si hay suficiente stock
    IF stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No hay suficiente stock disponible para este producto.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleados`
--

CREATE TABLE `empleados` (
  `id_empleado` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `cargo` varchar(50) DEFAULT NULL,
  `salario` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `empleados`
--

INSERT INTO `empleados` (`id_empleado`, `nombre`, `apellido`, `telefono`, `cargo`, `salario`) VALUES
(1, 'Pedro', 'Martínez', '555123456', 'Cajero', 1200000.00),
(2, 'Ana', 'Rodríguez', '555654321', 'Vendedor', 1300000.00),
(3, 'Luis', 'García', '555987654', 'Administrador', 2000000.00),
(4, 'Diana', 'Jiménez', '555246813', 'Cajero', 1250000.00),
(5, 'Miguel', 'Ortega', '555369147', 'Vendedor', 1350000.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historico`
--

CREATE TABLE `historico` (
  `id_historico` int(11) NOT NULL,
  `tabla_afectada` varchar(50) DEFAULT NULL,
  `id_registro` int(11) DEFAULT NULL,
  `accion` varchar(50) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `indice_pedidos_fecha`
--

CREATE TABLE `indice_pedidos_fecha` (
  `id_pedido` int(11) NOT NULL,
  `fecha` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `indice_pedidos_stock`
--

CREATE TABLE `indice_pedidos_stock` (
  `id_producto` int(11) NOT NULL,
  `cantidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_sesiones`
--

CREATE TABLE `logs_sesiones` (
  `id_log` int(11) NOT NULL,
  `usuario` varchar(100) NOT NULL,
  `ip` varchar(45) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metodos_pago`
--

CREATE TABLE `metodos_pago` (
  `id_metodo` int(11) NOT NULL,
  `metodo` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `categoria` varchar(50) DEFAULT NULL,
  `precio` decimal(10,2) NOT NULL,
  `stock` int(11) NOT NULL,
  `estado` enum('Bueno','Malo','Regular') NOT NULL DEFAULT 'Bueno',
  `id_proveedor` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `nombre`, `categoria`, `precio`, `stock`, `estado`, `id_proveedor`, `cantidad`) VALUES
(1, 'Lentejas', 'Legumbres', 5000.00, 88, 'Bueno', 1, 0),
(2, 'Frijoles', 'Legumbres', 6000.00, 80, 'Bueno', 1, 0),
(3, 'Garbanzos', 'Legumbres', 5500.00, 42, 'Regular', 2, 0),
(4, 'Arvejas', 'Legumbres', 5000.00, 57, 'Malo', 3, 0),
(5, 'Habas', 'Legumbres', 7000.00, 39, 'Bueno', 1, 0),
(6, 'Maíz', 'Cereales', 4000.00, 90, 'Regular', 4, 0),
(7, 'Quinua', 'Cereales', 12000.00, 30, 'Bueno', 3, 0),
(8, 'Chía', 'Semillas', 15000.00, 20, 'Malo', 4, 0),
(9, 'Linaza', 'Semillas', 9000.00, 50, 'Regular', 5, 0),
(10, 'Soya', 'Legumbres', 6500.00, 70, 'Bueno', 1, 0);

--
-- Disparadores `productos`
--
DELIMITER $$
CREATE TRIGGER `registrar_cambio_precio` BEFORE UPDATE ON `productos` FOR EACH ROW BEGIN
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO historial_precios (id_producto, precio_anterior, precio_nuevo, fecha_cambio)
        VALUES (OLD.id_producto, OLD.precio, NEW.precio, NOW());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id_proveedor` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id_proveedor`, `nombre`, `telefono`, `direccion`, `correo`) VALUES
(1, 'Proveedor A', '111222333', 'Zona Industrial 1', 'contacto@proveedora.com'),
(2, 'Proveedor B', '444555666', 'Zona Comercial 2', 'contacto@proveedorb.com'),
(3, 'Proveedor C', '777888999', 'Zona Industrial 3', 'contacto@proveedorc.com'),
(4, 'Proveedor D', '222333444', 'Zona Comercial 4', 'contacto@proveedord.com'),
(5, 'Proveedor E', '555666777', 'Zona Rural 5', 'contacto@proveedore.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `registro_compras`
--

CREATE TABLE `registro_compras` (
  `id_compra` int(11) NOT NULL,
  `fecha_compra` timestamp NOT NULL DEFAULT current_timestamp(),
  `id_proveedor` int(11) DEFAULT NULL,
  `id_empleado` int(11) DEFAULT NULL,
  `total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `registro_compras`
--

INSERT INTO `registro_compras` (`id_compra`, `fecha_compra`, `id_proveedor`, `id_empleado`, `total`) VALUES
(1, '2025-03-26 03:18:42', 1, 1, 30000.00),
(2, '2025-03-26 03:18:42', 2, 2, 25000.00),
(3, '2025-03-26 03:29:32', 3, 3, 35000.00),
(4, '2025-03-26 03:29:32', 4, 4, 40000.00),
(5, '2025-03-26 03:29:32', 5, 5, 28000.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles_permisos`
--

CREATE TABLE `roles_permisos` (
  `id_permiso` int(11) NOT NULL,
  `rol` varchar(50) NOT NULL,
  `modulo` varchar(100) NOT NULL,
  `permiso` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles_permisos`
--

INSERT INTO `roles_permisos` (`id_permiso`, `rol`, `modulo`, `permiso`) VALUES
(1, 'Cliente', 'Pedidos', 'LECTURA'),
(2, 'Cliente', 'Pagos', 'ESCRITURA'),
(3, 'Vendedor', 'Pedidos', 'ADMINISTRACION'),
(4, 'Administrador', 'Usuarios', 'ADMINISTRACION'),
(5, 'Proveedor', 'Productos', 'ADMINISTRACION'),
(6, 'Proveedor', 'Productos', 'ADMINISTRACION');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `usuario` varchar(100) NOT NULL,
  `clave` varchar(255) NOT NULL,
  `rol` enum('Cliente','Vendedor','Administrador','Proveedor') NOT NULL,
  `intentos_fallidos` int(11) DEFAULT 0,
  `bloqueado` tinyint(1) DEFAULT 0,
  `estado` enum('activo','bloqueado') DEFAULT 'activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `usuario`, `clave`, `rol`, `intentos_fallidos`, `bloqueado`, `estado`) VALUES
(1, 'admin', '$2y$10$0Ml/YKn/A/3yEy5ZUBRrL.VPyRVU/FILKRz.ddN1W317Pz8DHfhLe', 'Cliente', 0, 0, 'activo'),
(2, 'yeyher', '$2y$10$mERzynpFJEFJGkLS6Q0Wju9h.o5U79KnZZB0MIUre7Zz/h14H0S3y', 'Administrador', 0, 0, 'activo'),
(3, 'prove', '$2y$10$xq.RC0ht.VhCWdfPUt/39OVpTS/eSoQuP/dspgZOJOYNh2Jc9ltI.', 'Proveedor', 0, 0, 'activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id_venta` int(11) NOT NULL,
  `fecha_venta` timestamp NOT NULL DEFAULT current_timestamp(),
  `id_cliente` int(11) DEFAULT NULL,
  `id_empleado` int(11) DEFAULT NULL,
  `total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ventas`
--

INSERT INTO `ventas` (`id_venta`, `fecha_venta`, `id_cliente`, `id_empleado`, `total`) VALUES
(1, '2025-03-26 03:18:42', 1, 1, 15000.00),
(2, '2025-03-26 03:18:42', 2, 2, 12000.00),
(3, '2025-03-26 03:28:47', 3, 3, 18000.00),
(4, '2025-03-26 03:28:47', 4, 4, 25000.00),
(5, '2025-03-26 03:28:47', 5, 5, 14000.00),
(6, '2025-03-26 03:33:21', 1, 1, 25000.00);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_clientes_frecuentes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_clientes_frecuentes` (
`id_cliente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`cantidad_compras` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_compras_recientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_compras_recientes` (
`id_compra` int(11)
,`fecha_compra` timestamp
,`proveedor` varchar(100)
,`empleado` varchar(100)
,`total` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_empleados_mayor_venta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_empleados_mayor_venta` (
`id_empleado` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`cargo` varchar(50)
,`cantidad_ventas` bigint(21)
,`total_vendido` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_productos_bajo_stock`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_productos_bajo_stock` (
`id_producto` int(11)
,`nombre` varchar(100)
,`categoria` varchar(50)
,`stock` int(11)
,`estado` enum('Bueno','Malo','Regular')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_productos_mas_vendidos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_productos_mas_vendidos` (
`id_producto` int(11)
,`producto` varchar(100)
,`categoria` varchar(50)
,`total_vendido` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_proveedores_productos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_proveedores_productos` (
`id_proveedor` int(11)
,`proveedor` varchar(100)
,`id_producto` int(11)
,`producto` varchar(100)
,`categoria` varchar(50)
,`precio` decimal(10,2)
,`stock` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_ventas_por_cliente`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_ventas_por_cliente` (
`id_cliente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`total_ventas` bigint(21)
,`monto_total` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_clientes_frecuentes`
--
DROP TABLE IF EXISTS `vista_clientes_frecuentes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_clientes_frecuentes`  AS SELECT `c`.`id_cliente` AS `id_cliente`, `c`.`nombre` AS `nombre`, `c`.`apellido` AS `apellido`, count(`v`.`id_venta`) AS `cantidad_compras` FROM (`clientes` `c` join `ventas` `v` on(`c`.`id_cliente` = `v`.`id_cliente`)) GROUP BY `c`.`id_cliente`, `c`.`nombre`, `c`.`apellido` HAVING `cantidad_compras` > 5 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_compras_recientes`
--
DROP TABLE IF EXISTS `vista_compras_recientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_compras_recientes`  AS SELECT `c`.`id_compra` AS `id_compra`, `c`.`fecha_compra` AS `fecha_compra`, `p`.`nombre` AS `proveedor`, `e`.`nombre` AS `empleado`, `c`.`total` AS `total` FROM ((`registro_compras` `c` join `proveedores` `p` on(`c`.`id_proveedor` = `p`.`id_proveedor`)) join `empleados` `e` on(`c`.`id_empleado` = `e`.`id_empleado`)) WHERE `c`.`fecha_compra` >= curdate() - interval 30 day ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_empleados_mayor_venta`
--
DROP TABLE IF EXISTS `vista_empleados_mayor_venta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_empleados_mayor_venta`  AS SELECT `e`.`id_empleado` AS `id_empleado`, `e`.`nombre` AS `nombre`, `e`.`apellido` AS `apellido`, `e`.`cargo` AS `cargo`, count(`v`.`id_venta`) AS `cantidad_ventas`, sum(`v`.`total`) AS `total_vendido` FROM (`empleados` `e` left join `ventas` `v` on(`e`.`id_empleado` = `v`.`id_empleado`)) GROUP BY `e`.`id_empleado`, `e`.`nombre`, `e`.`apellido`, `e`.`cargo` ORDER BY sum(`v`.`total`) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_productos_bajo_stock`
--
DROP TABLE IF EXISTS `vista_productos_bajo_stock`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_productos_bajo_stock`  AS SELECT `productos`.`id_producto` AS `id_producto`, `productos`.`nombre` AS `nombre`, `productos`.`categoria` AS `categoria`, `productos`.`stock` AS `stock`, `productos`.`estado` AS `estado` FROM `productos` WHERE `productos`.`stock` <= 10 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_productos_mas_vendidos`
--
DROP TABLE IF EXISTS `vista_productos_mas_vendidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_productos_mas_vendidos`  AS SELECT `p`.`id_producto` AS `id_producto`, `p`.`nombre` AS `producto`, `p`.`categoria` AS `categoria`, sum(`dv`.`cantidad`) AS `total_vendido` FROM (`productos` `p` join `detalles_ventas` `dv` on(`p`.`id_producto` = `dv`.`id_producto`)) GROUP BY `p`.`id_producto`, `p`.`nombre`, `p`.`categoria` ORDER BY sum(`dv`.`cantidad`) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_proveedores_productos`
--
DROP TABLE IF EXISTS `vista_proveedores_productos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_proveedores_productos`  AS SELECT `p`.`id_proveedor` AS `id_proveedor`, `p`.`nombre` AS `proveedor`, `pr`.`id_producto` AS `id_producto`, `pr`.`nombre` AS `producto`, `pr`.`categoria` AS `categoria`, `pr`.`precio` AS `precio`, `pr`.`stock` AS `stock` FROM (`proveedores` `p` join `productos` `pr` on(`p`.`id_proveedor` = `pr`.`id_proveedor`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_ventas_por_cliente`
--
DROP TABLE IF EXISTS `vista_ventas_por_cliente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_ventas_por_cliente`  AS SELECT `c`.`id_cliente` AS `id_cliente`, `c`.`nombre` AS `nombre`, `c`.`apellido` AS `apellido`, count(`v`.`id_venta`) AS `total_ventas`, sum(`v`.`total`) AS `monto_total` FROM (`clientes` `c` left join `ventas` `v` on(`c`.`id_cliente` = `v`.`id_cliente`)) GROUP BY `c`.`id_cliente`, `c`.`nombre`, `c`.`apellido` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `carrito`
--
ALTER TABLE `carrito`
  ADD PRIMARY KEY (`id_carrito`),
  ADD KEY `id_usuario` (`id_usuario`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `detalles_compras`
--
ALTER TABLE `detalles_compras`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_compra` (`id_compra`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `detalles_ventas`
--
ALTER TABLE `detalles_ventas`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_venta` (`id_venta`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `empleados`
--
ALTER TABLE `empleados`
  ADD PRIMARY KEY (`id_empleado`);

--
-- Indices de la tabla `historico`
--
ALTER TABLE `historico`
  ADD PRIMARY KEY (`id_historico`);

--
-- Indices de la tabla `indice_pedidos_fecha`
--
ALTER TABLE `indice_pedidos_fecha`
  ADD PRIMARY KEY (`id_pedido`);

--
-- Indices de la tabla `indice_pedidos_stock`
--
ALTER TABLE `indice_pedidos_stock`
  ADD PRIMARY KEY (`id_producto`);

--
-- Indices de la tabla `logs_sesiones`
--
ALTER TABLE `logs_sesiones`
  ADD PRIMARY KEY (`id_log`);

--
-- Indices de la tabla `metodos_pago`
--
ALTER TABLE `metodos_pago`
  ADD PRIMARY KEY (`id_metodo`),
  ADD UNIQUE KEY `metodo` (`metodo`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`),
  ADD KEY `fk_proveedor` (`id_proveedor`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id_proveedor`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `registro_compras`
--
ALTER TABLE `registro_compras`
  ADD PRIMARY KEY (`id_compra`),
  ADD KEY `id_proveedor` (`id_proveedor`),
  ADD KEY `id_empleado` (`id_empleado`);

--
-- Indices de la tabla `roles_permisos`
--
ALTER TABLE `roles_permisos`
  ADD PRIMARY KEY (`id_permiso`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `usuario` (`usuario`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_empleado` (`id_empleado`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `carrito`
--
ALTER TABLE `carrito`
  MODIFY `id_carrito` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `detalles_compras`
--
ALTER TABLE `detalles_compras`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `detalles_ventas`
--
ALTER TABLE `detalles_ventas`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `empleados`
--
ALTER TABLE `empleados`
  MODIFY `id_empleado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `historico`
--
ALTER TABLE `historico`
  MODIFY `id_historico` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `logs_sesiones`
--
ALTER TABLE `logs_sesiones`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `metodos_pago`
--
ALTER TABLE `metodos_pago`
  MODIFY `id_metodo` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `registro_compras`
--
ALTER TABLE `registro_compras`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `roles_permisos`
--
ALTER TABLE `roles_permisos`
  MODIFY `id_permiso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `carrito`
--
ALTER TABLE `carrito`
  ADD CONSTRAINT `carrito_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `carrito_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `detalles_compras`
--
ALTER TABLE `detalles_compras`
  ADD CONSTRAINT `detalles_compras_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `registro_compras` (`id_compra`),
  ADD CONSTRAINT `detalles_compras_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `detalles_ventas`
--
ALTER TABLE `detalles_ventas`
  ADD CONSTRAINT `detalles_ventas_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`),
  ADD CONSTRAINT `detalles_ventas_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_proveedor` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`),
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`);

--
-- Filtros para la tabla `registro_compras`
--
ALTER TABLE `registro_compras`
  ADD CONSTRAINT `registro_compras_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`),
  ADD CONSTRAINT `registro_compras_ibfk_2` FOREIGN KEY (`id_empleado`) REFERENCES `empleados` (`id_empleado`);

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`),
  ADD CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`id_empleado`) REFERENCES `empleados` (`id_empleado`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
