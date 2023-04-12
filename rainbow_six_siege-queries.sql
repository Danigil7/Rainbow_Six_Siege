use rainbow_six_siege;

-- Muestre los datos de los personajes que utilicen el arma AUG A3:
select p.* , a.Nombre 
from personaje p 
inner join arma a on a.idArma = p.Arma_idArma 
where a.Nombre = 'AUG A3';

-- Muestre los datos de los personajes con nacionalidad rusa:
select p.*
from personaje p 
where p.Nacionalidad = 'Rusa' limit 1;


-- Mostrar los equipos y sus respectivos entrenadores, jugadores y personajes:
select Equipo.Nombre, Entrenador.Nombre, Jugador.Nombre, Personaje.Nombre 
from Equipo 
join Entrenador on Equipo.Entrenador_idEntrenador = Entrenador.idEntrenador 
join Jugador on Equipo.Jugador_idJugador = Jugador.idJugador 
join Personaje on Jugador.Personaje_idPersonaje = Personaje.idPersonaje;

-- Mostrar las habilidades de los personajes que tengan armas de tipo "Pistola":
select personaje.Nombre , Habilidad.Nombre , arma.Tipo
from Personaje 
join Arma on Personaje.Arma_idArma = Arma.idArma 
join Habilidad on Personaje.Habilidad_idHabilidad = Habilidad.idHabilidad 
where Arma.Tipo = 'Pistola';

-- nombre de los entrenadores y sus respectivos equipos, que tengan en su equipo un jugador que utilice la habilidad "Escaneo de huellas digitales".
select Entrenador.Nombre, Equipo.Nombre
from Entrenador
join Equipo on Entrenador.idEntrenador = Equipo.Entrenador_idEntrenador
join Jugador on Equipo.Jugador_idJugador = Jugador.idJugador
join Personaje on Jugador.Personaje_idPersonaje = Personaje.idPersonaje
join Habilidad on Personaje.Habilidad_idHabilidad = Habilidad.idHabilidad
where Habilidad.Nombre = 'Electrosensor';


-- VISTAS
use rainbow_six_siege;
create view rusos as
	select p.*
	from personaje p 
	where p.Nacionalidad = 'Rusa' limit 1;

select * from rusos;

use rainbow_six_siege;
create view entrenador_jug as
select e.Nombre as Equipo, e2.Nombre as Entrenador, j.Nombre as Jugador, p.Nombre as Personaje
from equipo e
inner join entrenador e2 on e.Entrenador_idEntrenador = e2.idEntrenador
inner join jugador j on e.Jugador_idJugador = j.idJugador
inner join personaje p on j.Personaje_idPersonaje = p.idPersonaje;


select * from entrenador_jug;



-- Procedimiento con funcion:
DROP PROCEDURE IF EXISTS componentes_equipos;
DELIMITER $$
CREATE PROCEDURE componentes_equipos(IN idJugador INT, OUT personajes_equipo VARCHAR(50))
BEGIN
    SET personajes_equipo = obtener_personajes_equipo(idJugador);
END$$
DELIMITER ;

CALL componentes_equipos(2, @personajes_equipo);
SELECT @personajes_equipo;



-- Procedimiento. Recibe como parámetro el nombre de un equipo y devuelve una lista de los jugadores que pertenecen a ese equipo, junto con el arma que utilizan:
drop procedure if exists GetJugadoresPorEquipo;
DELIMITER &&
create procedure GetJugadoresPorEquipo(IN equipo VARCHAR(50))
begin
  select j.Nombre AS Jugador, p.Nombre AS Personaje, a.Nombre AS Arma
  from Jugador j
  inner join Personaje p ON j.Personaje_idPersonaje = p.idPersonaje
  inner join Arma a ON p.Arma_idArma = a.idArma
  inner join Equipo e ON j.idJugador = e.Jugador_idJugador
  where e.Nombre = equipo;
end &&
DELIMITER ;

call GetJugadoresPorEquipo('Team Liquid');


-- Procedimiento con cursores
-- Recorre la tabla Personaje y por cada registro, imprime en la consola el nombre del personaje, su nacionalidad y el nombre de su habilidad.
drop procedure if exists listar_personajes;
DELIMITER &&
create procedure listar_personajes()
begin
    declare done int default false;
    declare nombre_personaje varchar(45);
    declare nacionalidad varchar(45);
    declare nombre_habilidad varchar(45);
    declare cur cursor for select p.Nombre, p.Nacionalidad, h.Nombre from Personaje p inner join Habilidad h on p.Habilidad_idHabilidad = h.idHabilidad;
    declare continue HANDLER for not found set done = true;
    open cur;
    read_loop: loop
        fetch cur into nombre_personaje, nacionalidad, nombre_habilidad;
        if done then
            leave read_loop;
        end if;
        select concat('Nombre: ', nombre_personaje, ', Nacionalidad: ', nacionalidad, ', Habilidad: ', nombre_habilidad) as datos_personaje;
    end loop;
    close cur;
end &&
DELIMITER ;

call listar_personajes();



-- FUNCIONES
-- Muestra el nombre del equipo, el nombre del entrenador y el nombre del arma utilizado por cada personaje en un equipo en particular
drop function if exists obtener_personajes_equipo;
DELIMITER &&
create function obtener_personajes_equipo(nombre_equipo VARCHAR(45))
returns VARCHAR(200)
DETERMINISTIC
begin
  declare result VARCHAR(200);
  select CONCAT_WS(', ', e.Nombre, e2.Nombre, a.Nombre) into result
  from Equipo e
  inner join Entrenador e2 on e.Entrenador_idEntrenador = e2.idEntrenador
  inner join Jugador j on e.Jugador_idJugador = j.idJugador
  inner join Personaje p on j.Personaje_idPersonaje = p.idPersonaje
  inner join Arma a on p.Arma_idArma = a.idArma
  where e.Nombre = nombre_equipo;
  
  return result;
end &&
DELIMITER ;

select obtener_personajes_equipo('G2');



-- Obtén el número de equipos por entrenador:
drop function if exists countEquiposPorEntrenador;
DELIMITER &&
create function countEquiposPorEntrenador(entrenador_id INT)
returns INT
DETERMINISTIC
begin
    declare equipo_count INT;
    select COUNT(*) INTO equipo_count
    from Equipo
    where Entrenador_idEntrenador = entrenador_id;
    return equipo_count;
end &&
DELIMITER ;

SELECT countEquiposPorEntrenador(1);



-- TRIGGERS
drop trigger if exists insert_jugador;
DELIMITER &&
CREATE TRIGGER insert_jugador AFTER INSERT ON Jugador
FOR EACH ROW
BEGIN
  INSERT INTO Equipo (idEquipo, Nombre, Jugador_idJugador)
  VALUES (1, 'Equipo 1', NEW.idJugador);
END &&
DELIMITER ;


DELIMITER &&
create trigger actualizar_nombre_jugador
after insert on Equipo
for each row
begin
    update Jugador
    set Nombre = new.Nombre
    where idJugador = new.Jugador_idJugador;
end &&
DELIMITER ;

select * from actualizar_nombre_jugador;
