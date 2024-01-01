/*Antes de ejecutar el script deberas descomentar la  linea 57 */ 


/*==============================================================*/
/* DBMS name:      PostgreSQL 8                                 */
/* Created on:     16/12/2023 12:16:15                          */
/*==============================================================*/

DROP INDEX IF EXISTS TIENE_FK;
DROP INDEX IF EXISTS CONTROL_PK;
DROP TABLE IF EXISTS CONTROL CASCADE;
DROP INDEX IF EXISTS MAQUINA_PK;
DROP TABLE IF EXISTS MAQUINA CASCADE;
DROP INDEX IF EXISTS EVENTO_PK;
DROP TABLE IF EXISTS EVENTO CASCADE;
DROP TYPE IF EXISTS EstadoMaquina;
DELETE FROM public.ultimoevento
WHERE CTID <= (SELECT CTID FROM public.ultimoevento LIMIT 1 OFFSET 500);

DROP TRIGGER IF EXISTS trigger_validar_evento_encendido ON EVENTO;
DROP TRIGGER IF EXISTS evento_aberiado_apagado_trigger ON EVENTO;
DROP TRIGGER IF EXISTS evento_aberiado_trigger ON EVENTO;
DROP TRIGGER IF EXISTS trigger_verificar_encendido ON EVENTO;

DROP FUNCTION IF EXISTS validarEventoEncendido();
DROP FUNCTION IF EXISTS actualizar_estado_maquina();
DROP FUNCTION IF EXISTS registrar_evento_aberiado();
DROP FUNCTION IF EXISTS verificarEncendido();


/*==============================================================*/
/* Table: CONTROL                                               */
/*==============================================================*/
CREATE TABLE CONTROL (
                         IDCONTROL            INT4 PRIMARY KEY,
                         IDMAQUINA            INT4 NOT NULL,
                         FECHACONTROL         DATE NOT NULL,
                         NUMEROPRENDASMALLAVADAS INT4 NOT NULL

);

/*==============================================================*/
/* Index: CONTROL_PK                                            */
/*==============================================================*/
CREATE UNIQUE INDEX CONTROL_PK ON CONTROL (IDCONTROL);

/*==============================================================*/
/* Index: TIENE_FK                                              */
/*==============================================================*/
CREATE INDEX TIENE_FK ON CONTROL (IDMAQUINA);

/*==============================================================*/
/* Table: MAQUINA                                               */
/*==============================================================*/
CREATE TYPE EstadoMaquina AS ENUM ('D', 'A');

CREATE TYPE EventoMaquina AS ENUM ('encendido','apagado','aberiado','reparado'); 
CREATE TABLE MAQUINA (
                         IDMAQUINA            INT4 PRIMARY KEY,
                         NOMBRE               VARCHAR(30) NOT NULL,
                         MARCA                VARCHAR(30) NOT NULL,
                         AÑOSFUNCIONALES      INT4 NOT NULL,
                         CAPACIDAD            INT4 NOT NULL,
                         ESTADO               EstadoMaquina NOT NULL
);

/*==============================================================*/
/* Index: MAQUINA_PK                                            */
/*==============================================================*/
CREATE UNIQUE INDEX MAQUINA_PK ON MAQUINA (IDMAQUINA);

ALTER TABLE CONTROL
    ADD CONSTRAINT FK_CONTROL_TIENE_MAQUINA FOREIGN KEY (IDMAQUINA)
        REFERENCES MAQUINA (IDMAQUINA)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

/*==============================================================*/
/* Table: EVENTO                                                */
/*==============================================================*/

CREATE TABLE EVENTO (
                        IDEVENTO      SERIAL PRIMARY KEY,
                        IDCONTROL     INT4 REFERENCES CONTROL(IDCONTROL) NOT NULL,
                        TIPOEVENTO    EventoMaquina NOT NULL,
                        HORAEVENTO         TIME NOT NULL
);

/*==============================================================*/
/* Index: EVENTO_PK                                             */
/*==============================================================*/
CREATE UNIQUE INDEX EVENTO_PK ON EVENTO (IDEVENTO);
ALTER TABLE EVENTO
    ADD CONSTRAINT FK_EVENTO_TIENE_CONTROL FOREIGN KEY (IDCONTROL)
        REFERENCES CONTROL (IDCONTROL)
        ON DELETE RESTRICT ON UPDATE RESTRICT;


-- INSERT para MAQUINA
INSERT INTO MAQUINA (IDMAQUINA, NOMBRE, MARCA, AÑOSFUNCIONALES, CAPACIDAD, ESTADO)
VALUES
    (1, 'Lavadora Samsung WF-8500N', 'Samsung', 2, 8, 'D'),
    (2, 'Lavadora LG WM3900HVA', 'LG', 1, 12, 'D'),
    (3, 'Lavadora Whirlpool WTW5700DW', 'Whirlpool', 3, 10, 'D'),
    (4, 'Lavadora Electrolux WED8657W', 'Electrolux', 5, 11, 'D'),
    (5, 'Lavadora Maytag MVWC885EW', 'Maytag', 2, 14, 'D'),
    (6, 'Lavadora Mabe FSM63XLS', 'Mabe', 4, 9, 'D'),
    (7, 'Lavadora Splendide WD2100XC', 'Splendide', 6, 10, 'D'),
    (8, 'Lavadora GE GTW460ASJWW', 'GE', 1, 13, 'D'),
    (9, 'Lavadora Speed Queen TR7', 'Speed Queen', 7, 8, 'D'),
    (10, 'Lavadora Equator EZ 4500', 'Equator', 3, 12, 'D');


select * from maquina;

INSERT INTO CONTROL (IDCONTROL, IDMAQUINA, FECHACONTROL, NUMEROPRENDASMALLAVADAS)
VALUES
    (1, 1, '2023-12-01', 100),
    (2, 2, '2023-12-01', 120),
    (3, 3, '2023-12-01', 90),
    (4, 4, '2023-12-01', 110),
    (5, 5, '2023-12-01', 130),
    (6, 6, '2023-12-01', 80),
    (7, 7, '2023-12-01', 95),
    (8, 8, '2023-12-01', 115),
    (9, 9, '2023-12-01', 70),
    (10, 10, '2023-12-01', 105);

select * from control;

CREATE OR REPLACE FUNCTION validarEventoEncendido()
    RETURNS TRIGGER AS $$
DECLARE
    estadoMaquina CHAR(1);
    ultimoEvento VARCHAR(20);
    horaUltimoEvento TIME;
BEGIN
    -- Obtener el estado actual de la máquina
    SELECT ESTADO
    INTO estadoMaquina
    FROM MAQUINA
    WHERE IDMAQUINA = (SELECT IDMAQUINA FROM CONTROL WHERE IDCONTROL = NEW.IDCONTROL);

    -- Obtener el último tipo de evento y hora registrado para el control
    SELECT TIPOEVENTO, HORAEVENTO
    INTO ultimoEvento, horaUltimoEvento
    FROM EVENTO
    WHERE IDCONTROL = NEW.IDCONTROL
    ORDER BY HORAEVENTO DESC
    LIMIT 1;


    -- Verificar las condiciones para el evento de encendido
    IF NEW.TIPOEVENTO = 'encendido' THEN
        IF estadoMaquina = 'D' AND (
            (ultimoEvento IS NULL) OR
            (ultimoEvento = 'apagado' OR ultimoEvento = 'reparado') AND (horaUltimoEvento IS NULL OR horaUltimoEvento < NEW.HORAEVENTO)
            ) THEN
            -- Registro en el log
            RAISE NOTICE 'Se permite el registro del evento de encendido. Estado: %, Último Evento: %, Última Hora: %, Nueva Hora: %',
                estadoMaquina, ultimoEvento, horaUltimoEvento, NEW.HORAEVENTO;
            RETURN NEW;
        ELSE
            -- Registro en el log
            RAISE NOTICE 'No se permite el registro del evento de encendido. Estado: %, Último Evento: %, Última Hora: %, Nueva Hora: %',
                estadoMaquina, ultimoEvento, horaUltimoEvento, NEW.HORAEVENTO;
            RAISE EXCEPTION 'No se puede registrar un evento de encendido en estas condiciones.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_evento_encendido
    BEFORE INSERT ON EVENTO
    FOR EACH ROW
    WHEN (NEW.TIPOEVENTO = 'encendido')
EXECUTE FUNCTION validarEventoEncendido();



CREATE OR REPLACE FUNCTION registrar_evento_aberiado()
    RETURNS TRIGGER AS $$
DECLARE
    horaUltimoEvento TIME;
BEGIN
    -- Obtener la hora del último evento registrado para el control
    SELECT HORAEVENTO
    INTO horaUltimoEvento
    FROM EVENTO
    WHERE IDCONTROL = NEW.IDCONTROL
    ORDER BY HORAEVENTO DESC
    LIMIT 1;

    -- Verificar las condiciones para el evento de aberiado
    IF NEW.TIPOEVENTO = 'aberiado' THEN
        -- Verificar si la hora del evento anterior es menor
        IF horaUltimoEvento IS NULL OR horaUltimoEvento <= NEW.horaevento THEN

            -- Cambiar estado de la máquina a 'A'
            UPDATE MAQUINA
            SET ESTADO = 'A'
            WHERE IDMAQUINA = (SELECT IDMAQUINA FROM CONTROL WHERE IDCONTROL = NEW.IDCONTROL);

            -- Insertar evento 'apagado' sumando un segundo
            INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
            VALUES (NEW.IDCONTROL, 'apagado', NEW.horaevento - INTERVAL '1 second');


            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'La hora del evento de aberiado debe ser mayor que la del evento anterior.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER evento_aberiado_trigger
    before INSERT ON EVENTO
    FOR EACH ROW
    WHEN (NEW.TIPOEVENTO = 'aberiado')
EXECUTE FUNCTION registrar_evento_aberiado();




CREATE OR REPLACE FUNCTION validarEventosPrevios()
    RETURNS TRIGGER AS $$
DECLARE
    estadoMaquina CHAR(1);
    eventoAnterior1 VARCHAR(20);
    eventoAnterior2 VARCHAR(20);
BEGIN
    -- Obtener el estado actual de la máquina
    SELECT ESTADO
    INTO estadoMaquina
    FROM MAQUINA
    WHERE IDMAQUINA = (SELECT IDMAQUINA FROM CONTROL WHERE IDCONTROL = NEW.IDCONTROL);

    -- Obtener los dos eventos anteriores al nuevo evento
    SELECT TIPOEVENTO
    INTO eventoAnterior1
    FROM EVENTO
    WHERE IDCONTROL = NEW.IDCONTROL
    ORDER BY HORAEVENTO DESC
    LIMIT 1 OFFSET 0;

    SELECT TIPOEVENTO
    INTO eventoAnterior2
    FROM EVENTO
    WHERE IDCONTROL = NEW.IDCONTROL
    ORDER BY HORAEVENTO DESC
    LIMIT 1 OFFSET 1;

    if estadoMaquina = 'D' then
        RAISE EXCEPTION 'a maquina no necesita reparacion.';
    end if;

    IF estadoMaquina = 'A' AND NEW.TIPOEVENTO = 'reparado' THEN
        IF eventoAnterior2 = 'apagado' AND eventoAnterior1 = 'aberiado' THEN
            UPDATE MAQUINA
            SET ESTADO = 'D'
            WHERE IDMAQUINA = (SELECT IDMAQUINA FROM CONTROL WHERE IDCONTROL = NEW.IDCONTROL);

            RETURN NEW;

        ELSE
            RAISE EXCEPTION 'No se puede registrar un evento de reparado sin eventos previos de apagado y aberiado.';
        END IF;
    ELSE

    END IF;


    RETURN NEW;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_eventos_previos
    BEFORE INSERT ON EVENTO
    FOR EACH ROW
    WHEN (NEW.TIPOEVENTO = 'reparado')
EXECUTE FUNCTION validarEventosPrevios();

CREATE OR REPLACE FUNCTION validarEventoApagado()
    RETURNS TRIGGER AS $$
DECLARE
    horaEventoAnterior TIME;
    eventoAnterior VARCHAR(20);
BEGIN
    SELECT HORAEVENTO, TIPOEVENTO
    INTO horaEventoAnterior, eventoAnterior
    FROM EVENTO
    WHERE IDCONTROL = NEW.IDCONTROL
    ORDER BY HORAEVENTO DESC
    LIMIT 1 OFFSET 0;

    IF NEW.TIPOEVENTO = 'apagado' THEN
        IF eventoAnterior = 'encendido' AND NEW.horaevento > horaEventoAnterior THEN
            -- Registro en el log
            RAISE NOTICE 'Se permite el registro del evento de apagado. Evento Anterior: %, Hora Anterior: %, Nueva Hora: %',
                eventoAnterior, horaEventoAnterior, NEW.horaevento;
            RETURN NEW;
        ELSE
            -- Registro en el log
            RAISE EXCEPTION 'No se puede registrar un evento de apagado en estas condiciones.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_validar_evento_apagado
    BEFORE INSERT ON EVENTO
    FOR EACH ROW
    WHEN (NEW.TIPOEVENTO = 'apagado')
EXECUTE FUNCTION validarEventoApagado();

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'encendido', '14:39:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'apagado', '14:42:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'encendido', '14:49:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'apagado', '14:52:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'encendido', '14:59:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'apagado', '16:52:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'encendido', '17:22:00');


INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'aberiado', '17:30:00');


INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'reparado', '18:30:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'encendido', '18:59:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'apagado', '19:52:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'encendido', '19:59:00');

INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'aberiado', '20:20:00');


INSERT INTO EVENTO (IDCONTROL, TIPOEVENTO, HORAEVENTO)
VALUES (1, 'reparado', '20:30:00');

