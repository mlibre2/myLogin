## myLogin

<img width="800" height="600" alt="1" src="https://github.com/user-attachments/assets/bbc63ff2-34e8-44cf-a575-bc7b4ab930c4" />

Simple programa de código abierto para bloquear y/o desbloquear la pantalla del Escritorio de Windows con funcionalidades para desactivar teclas especificas del teclado y clic del mouse, imposibilitando hacer uso normal del sistema hasta que este sea liberado por una contraseña previamente creada por el usuario administrador.

## ¿Cómo usar?

Primeramente debes crear un Hash para abrir el login, el programa dispone de una serie de parámetros para poder generarlo, el primero es:

- ``/GenerateHash`` ó ``/gh``
  
  Para hacer uso del parámetro, debes ejecutarlo de la siguiente manera:
  ``MyLogin.exe /GenerateHash``
  
> [!IMPORTANT]
> Una vez ejecutado, sigas las instrucciones hasta obtener su Hash como este `0xBB7B85A436B38DFAE3756DDF54AF46CD`
> guárdalo que lo vamos usar en el siguiente paso.
  

- ``/PassHash`` ó ``/ph``

  Una vez generado el Hash ya puedes hacer uso de este parámetro, recuerda que este Hash es la Clave y/o Contraseña que añadiste anteriormente en texto plano. Si no la has generado no podrás abrir el programa ya que es requerido para poder desbloquearlo una vez abierto. Si ya lo generaste ya puedes iniciar el programa de la siguiente manera: ``MyLogin.exe /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD``

> [!NOTE]
> Los siguientes parámetros son opcionales, no son requeridos.
  

- ``/DisableTaskMgr`` ó ``/dt``

  Con este parámetro podrás deshabilitar el Administrador de Tareas para dificultar omitir el login, como por ejemplo finalizando el proceso.
  

- ``/DisableExplorer`` ó ``/de``

  Con este parámetro podrás deshabilitar temporalmente el Explorador de Windows, impidiendo que no aparezca la barra de tareas, iconos del escritorio ni sea posible abrir el menú inicio.
  

- ``/Style`` ó ``/st``

  Con este parámetro podrás elegir estilos disponibles como los son el modo dark (oscuro) y modo aqua que es de color celeste. De forma predeterminada el estilo es blanco.

  Por ejemplo, habilitar modo dark:

  ``MyLogin.exe /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD /Style 1``

## ¿Cómo lo descargo?

Dirígete a la sección de [lanzamientos](https://github.com/mlibre2/myLogin/releases) donde estarán disponibles las últimas versiones compiladas.

## ¿Cómo lo compilo manualmente?

Puedes hacer uso del archivo [CMD](https://github.com/mlibre2/myLogin/tree/main/compile) cuyos requisitos es tener instalado el AutoIt3 con Aut2Exe

## ¿Puedo ayudar en su desarrollo?

Por supuesto, todas las sugerencias son bienvenidas ;)
