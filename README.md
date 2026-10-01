# Adulis Pythonshop

Aplicação desktop para processamento e manipulação digital de imagens, desenvolvida em Python com QT/QML.

# Desenvolvido por
* Felipe Adulis
* Rauan Polli

## Como Executar a Aplicação

A aplicação pode ser executada diretamente via .exe compilado (Windows) ou via código python.

### Opção 1: Executável Pronto (Recomendado)

Esta opção não exige a instalação do Python ou de bibliotecas adicionais na máquina.

1. Navegue até a pasta `dist/pythonshop/`.
2. Execute o arquivo `pythonshop.exe`.

### Opção 2: Via Código Python

#### Pré-requisitos
* Python 3.10 ou superior

#### Passos para instalação e execução:

1. Abra o terminal na pasta raiz do projeto.
2. Instale as bibliotecas necessárias:
   ```
   pip install PySide6 opencv-python numpy
   ````
3. Execute o script principal:
   ```
   python pythonshop.py
   ````

## Guia de Uso

1. **Carregar uma Imagem:** 
   Clique no botão "Abrir Imagem" no centro da tela ou utilize o atalho `Ctrl + O` / menu "Arquivo > Abrir...".
2. **Aplicar Ajustes e Filtros:** 
   Utilize os controles no painel lateral esquerdo (sliders, spinboxes e joystick). As alterações são refletidas em tempo real na tela de visualização.
3. **Confirmar ou Descartar Alterações:** 
   * Para fixar uma alteração antes de aplicar outra, clique no botão **Aplicar** do respectivo controle.
   * Para cancelar a alteração em andamento no controle ativo, clique no botão **Reset** desse controle.
4. **Restaurar Imagem:** 
   Para descartar todas as modificações e voltar à imagem original carregada, clique no botão **Resetar Imagem**.
5. **Salvar o Resultado:** 
   Utilize o botão **Salvar** (`Ctrl + S`) para sobrescrever a alteração no caminho ativo ou selecione "Arquivo > Salvar Como..." (`Ctrl + Shift + S`) para escolher outro diretório.

---

## Lista de Funções Implementadas

### Módulo de Arquivo e Atalhos
* **Abrir Imagem (`Ctrl + O`):** Suporta os formatos PNG, JPG e JPEG.
* **Salvar Imagem (`Ctrl + S`):** Salva as alterações feitas na imagem no caminho atual.
* **Salvar Como (`Ctrl + Shift + S`):** Abre a caixa de diálogo para salvar a imagem em um novo caminho.
* **Resetar Imagem:** Restaura o estado da imagem de volta ao arquivo original aberto.
* **Exibir/Ocultar Histograma:** Alterna a visibilidade do painel do histograma lateral.

### Transformações Pontuais
* **Escala de Cinza:** Converte a imagem BGR para níveis de cinza (Grayscale).
* **Ajuste de Brilho:** Slider dinâmico com variação de -255 a +255.
* **Fator de Contraste:** Slider dinâmico com fator multiplicador de 0.0x a 3.0x.
* **Negativo da Imagem:** Inverte as intensidades de todos os pixels (255 - valor).
* **Alongamento de Contraste:** Mapeia a faixa dinâmica da imagem para a escala completa de 0 a 255.
* **Equalização de Histograma:** Redistribui o histograma de frequências. Inclui suporte a **CLAHE** (Contrast Limited Adaptive Histogram Equalization) via checkbox.

### Transformações Geométricas
* **Rotação:** Slider contínuo de rotação angular entre -180° e +180° com ajuste dinâmico de borda.
* **Translação (Joystick 2D):** Controle interativo X/Y para transladar a imagem no plano 2D.
* **Espelhamento:** Botões dedicados para inversão horizontal e vertical.

### Transformações por Vizinhança (Filtros)
* **Filtro da Média:** Suavização espacial configurável via tamanho de Kernel (1x1 a 9x9).
* **Filtro Gaussiano:** Suavização Gaussiana com ajuste simultâneo de tamanho de Kernel e valor de Sigma ($\sigma$), aceitando entrada numérica via teclado.
* **Adição de Ruído:** Adiciona ruído com distribuição normal gaussiana à imagem.
