## myLogin <img align="right" width="32" height="32" alt="Ico" src="https://github.com/user-attachments/assets/c8c08b6a-927c-4278-917a-c23b10e6491d" />

<img width="800" height="600" alt="Captura de Pantalla" src="https://github.com/user-attachments/assets/bbc63ff2-34e8-44cf-a575-bc7b4ab930c4" />

Simple programa de código abierto para bloquear/desbloquear la pantalla del Escritorio de Windows con opciones avanzadas:
- Desactiva teclas específicas del teclado y clics del mouse
- Impide el uso normal del sistema
- Solo se desbloquea con una contraseña configurada por el administrador

## 🚀 ¿Cómo empezar/usar?

### 1. Genera tu contraseña (Hash)
Ejecuta el programa con el parámetro:

- ``/GenerateHash`` ó ``/gh``

  Ejemplo:
  ``MyLogin.exe /GenerateHash``

> [!IMPORTANT]
> Una vez ejecutado, sigas las instrucciones hasta obtener el Hash generado (ej: `0xBB7B85A436B38DFAE3756DDF54AF46CD`)
> 🔐 Guardalo, será tu contraseña "cifrada", la usaremos para iniciar el programa.

### 2. Iniciar el bloqueo
Usa tu Hash para iniciar el programa:

- ``/PassHash`` ó ``/ph``

  Ejemplo:
  ``MyLogin.exe /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD``

  Recuerda que este Hash es la Contraseña que añadiste anteriormente en texto plano pero "cifrada". Si no la has generado no podrás abrir el programa ya que es requerido para poder desbloquearlo una vez abierto, la contraseña que vas usar para desbloquearlo es la que ingresaste para generar el hash.

> [!NOTE]
> ⚙️ Los siguientes parámetros son opcionales, no son requeridos.
  

- ``/DisableTaskMgr`` ó ``/dt``

  Con este parámetro podrás deshabilitar el Administrador de Tareas para dificultar omitir el login, como por ejemplo finalizar el proceso.
  

- ``/DisableExplorer`` ó ``/de``

  Con este parámetro podrás deshabilitar temporalmente el Explorador de Windows, impidiendo que no aparezca la barra de tareas, iconos del escritorio ni sea posible abrir el menú inicio.


- ``/DisablePowerOff`` ó ``/dp``
  
    Con este parámetro podrás deshabilitar el botón de Apagar **(disponible desde la versión [1.1](https://github.com/mlibre2/myLogin/releases/tag/1.1))**


- ``/DisableReboot`` ó ``/dr``
  
    Con este parámetro podrás deshabilitar el botón de Reiniciar **(disponible desde la versión [1.1](https://github.com/mlibre2/myLogin/releases/tag/1.1))**
  

- ``/Style`` ó ``/st``

  Con este parámetro podrás cambiar el diseño (0=Blanco, 1=Oscuro, 2=Celeste)

  Ejemplo, habilitar modo dark (oscuro):

  ``MyLogin.exe /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD /Style 1``

  Ejemplo con todas las opciones:

  ``MyLogin.exe /ph 0xBB7B85A436B38DFAE3756DDF54AF46CD /dt /de /st 1``

## 📥 ¿Cómo lo descargo?

Dirígete a la sección de [lanzamientos](https://github.com/mlibre2/myLogin/releases) donde estarán disponibles las últimas versiones compiladas.

## 🔌 ¿Cómo lo instalo/configuro para que inicie de forma automática?
### Métodos recomendados:

Tienes varios métodos de cómo auto-ejecutarlo, elije una de ellas:

| # | Método | Proceso | Dificultad | Velocidad | Recomendado | Oculto |
|------|-----|-----|-----|-----|-----|-----|
| 1 | Winlogon | Regedit | Alta | Rapida | :heavy_check_mark: | :heavy_check_mark: |
| 2 | Logon Scripts | Gpedit | Media | Media | :heavy_check_mark: | :heavy_check_mark: |
| 3 | Run StartUp | Windows | Baja | Media | :heavy_check_mark: | :x: |
| 4 | Tarea Programada | Windows | Baja | Lenta | :x: | :x: |

1. **Winlogon**:
   
   Es la manera más rápida de iniciar el programa, ya que abrirse el proceso ``explorer.exe``, en este momento se ejecuta justo después de mostrar el escritorio.
   - Abre ``regedit``
   - Ve a ``[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]``
   - Modifica la clave ``Shell``:
     
  Ejemplo:
  ```
  explorer.exe, "C:\myLogin.exe" /PassHash 0xBB7B85A436B38DFAE3756DDF54AF46CD
  ```

  
2. **Logon Scripts**:

   - Abre ``gpedit.msc``
   - Ve a -> ``Config. Usuario -> Config. Windows -> Script -> Iniciar Sesión -> Agregar``
   - En nombre del script: ``C:\myLogin.exe``
   - Parámetros del script: ``/ph 0xBB7B85A436B38DFAE3756DDF54AF46CD``
   - Aceptar
   - Aplicar y Aceptar

  
3. **Run StartUp**:

   - Crea un acceso directo en: ``C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp``
     
     Cuyas propiedades quedarian asi: ``C:\myLogin.exe /ph 0xBB7B85A436B38DFAE3756DDF54AF46CD``
   
4. **Tarea Programada**:
  
   - Este método suele ejecutarse con demoras dependiendo de cuantos procesos y tareas tengas por delante, por ende no me simpatiza.
     si aún consideras usarlo, has lo siguiente.
      - Abre ``cmd``
      - Ingresa ``schtasks /create /tn "myLogin" /tr "\"C:\myLogin.exe\" /ph 0xBB7B85A436B38DFAE3756DDF54AF46CD" /sc onlogon``
      - Y presiona ENTER.
      - Ya creado, "debería" ejecutarse cada vez que el usuario inicie sesión.
        
        Si deseas eliminarla, ingresa el comando: ``schtasks /delete /tn "myLogin" /f``

> [!TIP]
> Para máxima seguridad, usa los métodos "Ocultos" (Winlogon o Scripts) que impiden que otros desactiven el programa fácilmente.

## ¿Cómo lo compilo manualmente?

Puedes hacer uso del archivo [CMD](https://github.com/mlibre2/myLogin/tree/main/compile) cuyos requisitos es tener instalado el AutoIt3 con Aut2Exe

## ¿Puedo ayudar en su desarrollo?

Por supuesto, todas las sugerencias son bienvenidas ;)
