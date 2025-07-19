###### :world_map: Idiomas soportados: [Ingles](https://github.com/mlibre2/myLogin/blob/main/README.md) - [Español](#)

# myLogin ![GitHub Release](https://img.shields.io/github/v/release/mlibre2/myLogin?style=for-the-badge) ![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/mlibre2/myLogin/latest/total?style=for-the-badge) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/mlibre2/myLogin/total?style=for-the-badge) <img align="right" width="32" height="32" alt="Ico" src="https://github.com/user-attachments/assets/c8c08b6a-927c-4278-917a-c23b10e6491d" />

<img width="800" height="600" alt="es" src="https://github.com/user-attachments/assets/f89433fd-8628-4587-9d23-6afb3f6f450c" />

Simple programa de código abierto para bloquear la pantalla del Escritorio de Windows con opciones avanzadas:
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
> Una vez ejecutado, sigas las instrucciones hasta obtener el Hash generado (ej: `0x9461E4B1394C6134483668F09CCF7B93`)
> 🔐 Guardalo, será tu contraseña "cifrada", la usaremos para iniciar el programa.

### 2. Iniciar el bloqueo
Usa tu Hash para iniciar el programa:

- ``/PassHash`` ó ``/ph``

  Ejemplo:
  ``MyLogin.exe /PassHash 0x9461E4B1394C6134483668F09CCF7B93``

  Este Hash es la contraseña que ingresaste anteriormente en texto plano pero "cifrada".
   - Si no has generado un hash, no podrás acceder al programa, ya que es necesario para desbloquearlo.
   - La contraseña que debes usar para desbloquearlo, es la original (la que ingresaste al crear el hash), no el hash cifrado.

> [!NOTE]
> ⚙️ Los siguientes parámetros son opcionales, no son requeridos.
  

- ``/DisableTaskMgr`` ó ``/dt``

  Con este parámetro podrás deshabilitar el **Administrador de tareas** para dificultar omitir el login, como por ejemplo finalizar el proceso.
  

- ``/DisableExplorer`` ó ``/de``

  Con este parámetro podrás deshabilitar temporalmente el **Explorador de Windows**, impidiendo que no aparezca la barra de tareas, iconos del escritorio ni sea posible abrir el menú inicio.


- ``/DisablePowerOff`` ó ``/dp``
  
    Con este parámetro podrás deshabilitar el botón de Apagar **(disponible desde [v1.1](https://github.com/mlibre2/myLogin/releases/tag/1.1))**


- ``/DisableReboot`` ó ``/dr``
  
    Con este parámetro podrás deshabilitar el botón de Reiniciar **(disponible desde [v1.1](https://github.com/mlibre2/myLogin/releases/tag/1.1))**
  

- ``/Style`` ó ``/st``

  Con este parámetro podrás cambiar el diseño (0=Blanco "predeterminado", 1=Oscuro, 2=Celeste)

  Ejemplo, habilitar modo dark (oscuro):

  ``MyLogin.exe /PassHash 0x9461E4B1394C6134483668F09CCF7B93 /Style 1``

  Ejemplo con todas las opciones:

  ``MyLogin.exe /ph 0x9461E4B1394C6134483668F09CCF7B93 /dt /de /st 1``

## 📥 ¿Cómo lo descargo?

Dirígete a la sección [Releases](https://github.com/mlibre2/myLogin/releases) donde estarán disponibles las últimas versiones compiladas.

## 🔌 ¿Cómo lo instalo/configuro para que inicie de forma automática?
### Métodos recomendados:

Tienes varios métodos de cómo ``auto-ejecutarlo``, elije una de ellas:

| # | Método | Proceso | Dificultad | Velocidad | Recomendado | Oculto |
|------|-----|-----|-----|-----|-----|-----|
| 1 | Winlogon | Regedit | Alta | Rápida | :heavy_check_mark: | :heavy_check_mark: |
| 2 | Logon Scripts | Gpedit | Media | Media | :heavy_check_mark: | :heavy_check_mark: |
| 3 | Run StartUp | Windows | Baja | Media | :heavy_check_mark: | :x: |
| 4 | Tarea Programada | Windows | Baja | Lenta | :x: | :x: |

1. **Winlogon**:
   
   Es uno de los métodos más rápidos de iniciar el programa, ya que se ejecuta inmediatamente después de que el usuario inicia sesión, justo al mostrar el escritorio.
   - Abre ``regedit``
   - Ve a ``[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]``
   - Modifica la clave ``Shell``:
     
  Ejemplo:
  ```
  explorer.exe, "C:\myLogin.exe" /PassHash 0x9461E4B1394C6134483668F09CCF7B93
  ```

  
2. **Logon Scripts**:

   - Abre ``gpedit.msc``
   - Ve a -> ``Config. Usuario -> Config. Windows -> Script -> Iniciar Sesión -> Agregar``
   - En nombre del script: ``C:\myLogin.exe``
   - Parámetros del script: ``/ph 0x9461E4B1394C6134483668F09CCF7B93``
   - Aceptar
   - Aplicar y Aceptar

  
3. **Run StartUp**:

   - Crea un acceso directo en: ``C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp``
     
     Cuyas propiedades quedarian asi: ``C:\myLogin.exe /ph 0x9461E4B1394C6134483668F09CCF7B93``
   
4. **Tarea Programada**:
  
   - Este método puede tardar dependiendo de la cantidad de procesos y tareas en cola, por lo que no lo recomiendo.
     Si aun así decides usarlo, sigue estos pasos:
      - Abre ``cmd``
      - Ingresa ``schtasks /create /tn "myLogin" /tr "\"C:\myLogin.exe\" /ph 0x9461E4B1394C6134483668F09CCF7B93" /sc onlogon``
      - Y presiona ENTER.
      - Ya creado, "debería" ejecutarse cada vez que el usuario inicie sesión.
        
        Si deseas eliminar la tarea, ingresa el comando: ``schtasks /delete /tn "myLogin" /f``

> [!TIP]
> Para máxima seguridad, usa los métodos "Ocultos" (Winlogon o Scripts) que impiden que otros desactiven el programa fácilmente.

## :hammer_and_wrench: ¿Cómo lo compilo manualmente?

Puedes hacer uso del archivo [CMD](https://github.com/mlibre2/myLogin/tree/main/compile) cuyos requisitos es tener instalado el AutoIt3 con Aut2Exe

## :earth_americas: ¿Cómo añado más idiomas?

A partir de la versión ``1.5``, puedes ayudar a añadir soporte para idiomas que aún no estén disponibles. Los archivos se encuentran en la carpeta [lang/](https://github.com/mlibre2/myLoginCompile/tree/main/lang)

## :building_construction: ¿Puedo ayudar en su desarrollo?

Por supuesto, todas las sugerencias son bienvenidas ;)

> [!CAUTION]
> Para reportar cualquier ``Bug`` :spider: crea un [Issues](https://github.com/mlibre2/myLogin/issues) con sus detalles del problema !
