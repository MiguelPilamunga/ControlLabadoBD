# Descripción General del Código: Sistema de Control de Eventos para Máquinas en PostgreSQL

Este conjunto de scripts SQL se utiliza para crear y gestionar una base de datos en PostgreSQL diseñada para el control de eventos en máquinas. La estructura de la base de datos consta de tres tablas principales: `MAQUINA`, `CONTROL`, y `EVENTO`. La relación entre ellas permite rastrear el estado, el historial de controles y los eventos asociados a cada máquina.

## Características Principales

### 1. Tablas Principales:
   - **MAQUINA**: Almacena información sobre las máquinas, como nombre, marca, años funcionales, capacidad y estado actual ('D' para apagada, 'A' para encendida).
   - **CONTROL**: Registra los controles realizados en cada máquina, incluyendo la fecha del control y el número de prendas lavadas.
   - **EVENTO**: Registra eventos asociados a cada control, como encendido, apagado, averiado, y reparado.

### 2. Validaciones y Triggers:
   - Se implementan funciones y triggers para validar y controlar el registro de eventos:
      - `validarEventoEncendido()`: Permite el registro del evento de encendido según condiciones específicas.
      - `registrar_evento_aberiado()`: Cambia el estado de la máquina a 'A' y registra un evento de apagado cuando se detecta un evento de averiado.
      - `validarEventosPrevios()`: Permite el registro de eventos de reparado solo si hay eventos previos de apagado y averiado.
      - `validarEventoApagado()`: Permite el registro del evento de apagado solo si el evento anterior fue encendido.

### 3. Tipos de Datos y Enumerados:
   - Se utiliza el tipo de dato enumerado `EstadoMaquina` para definir los estados posibles de la máquina ('D' y 'A').

### 4. Integridad Referencial:
   - Se establecen restricciones de clave foránea para mantener la integridad referencial entre las tablas `CONTROL` y `EVENTO` con la tabla `MAQUINA`.

### 5. Datos de Ejemplo:
   - Se proporcionan ejemplos de inserción de datos para las tablas `MAQUINA` y `CONTROL` con máquinas y controles simulados.

## Uso Recomendado

Este código está destinado a ser utilizado como base para la creación de un sistema de control de eventos en máquinas. Se pueden adaptar las funciones y triggers según las necesidades específicas del entorno de la máquina y el control de eventos. Además, se recomienda revisar y ajustar los datos de ejemplo para reflejar con precisión el contexto de uso.

## Requisitos

- PostgreSQL 8 o superior.

## Notas Importantes

- Antes de ejecutar este código en un entorno de producción, se recomienda revisar y adaptar las configuraciones y restricciones según los requisitos específicos del sistema.
