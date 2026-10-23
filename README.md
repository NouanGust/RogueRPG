# RogueRPG

Protótipo de RPG de combate por turnos com elementos roguelite, em Godot 4.6.
Personagens em sprites são apresentados em cenários 3D. A prioridade atual é
estabilizar um ciclo completo antes de ampliar o conteúdo.

## Executar

Abra `project.godot` no Godot 4.6.3 e execute o projeto (F6 executa somente a cena
aberta; F5 usa a entrada oficial). A cena inicial é `Scenes/3D/lobby_3d.tscn`.

Fluxo suportado: menu → criar/carregar perfil → escolher classe → rolar atributos
→ lobby/loja/baú → combate → recompensa → próximo encontro ou acampamento
→ retorno ao lobby. Um personagem morto volta à seleção de classe.

## Regras atuais

- Força, Inteligência, Fé e Agilidade são roladas conforme os dados da classe.
  Há uma rerrolagem geral. Uma animação de rolagem bloqueia ações concorrentes.
- Ataque = ataque base da classe + atributo principal; defesa = defesa base +
  metade da Agilidade, arredondada para baixo; HP = HP base + Força.
- Dano = ataque − defesa, com mínimo de 1. Uma derrota só concede recompensas
  uma vez, e ações ficam bloqueadas durante animações, entrada de inimigos e loot.
- XP pertence ao personagem. Cada nível exige `nível atual × 20` XP, consome esse
  valor e acrescenta um d4 a cada atributo. O excedente de XP é preservado.
- A cada cinco vitórias na mesma expedição há um acampamento seguro. Avançar sai
  desse acampamento e inicia o próximo encontro; retornar não aplica penalidade.
- Fugir durante combate exige d20 ≥ 10; sucesso custa 30% das moedas (arredondado
  para baixo) e um item aleatório da mochila, quando houver. Falha consome o turno.
- A morte elimina imediatamente o personagem, seus atributos, nível e XP.
  **Moedas e melhorias permanentes do perfil continuam.**
- O lobby recupera a vida do personagem. Carregar um perfil leva ao lobby, não
  retoma uma animação ou um turno interrompido. Cada vitória salva moedas e evolução.
- Mochila e baú mantêm a persistência por perfil que já existia no protótipo.
  Uma mudança na política de perda de itens por morte é uma decisão de design futura.
- Poções não são gastas com vida cheia. Elixires afetam o atributo principal ou
  Agilidade, refletindo o bônus no combate. Dados e relíquias sem efeito implementado
  não são vendidos na loja atual nem consumidos caso existam num perfil antigo.

## Estrutura

- `Scenes/3D/`: fluxo principal, personagens, lobby e controlador de combate.
- `Scenes/battle/battle_ui.gd`: interface compartilhada utilizada pelo combate 3D.
- `Scripts/Components/`: regras de vida, atributos e cálculo de dano.
- `Scripts/resources/`: dados das classes, inimigos e itens.
- `Scripts/controllers/game_state.gd`: estado do personagem e da expedição em memória.
- `Scripts/globals/save_manager.gd`: perfis, validação, migração e gravação.
- `Scripts/controllers/camp_controller.gd` e `Scenes/main/camp.tscn`: loja e baú
  incorporados ao lobby 3D.
- `Tests/`: regressões de regras e integração de cenas.

As telas 2D anteriores em `Scenes/run/` e `Scenes/battle/BattleScene.tscn` são
legadas. Algumas peças de UI dessas pastas continuam compartilhadas: não remova
as pastas inteiras. Os antigos menu principal e controlador de batalha encaminham
para o fluxo 3D; não devem receber novas regras de jogo. O componente antigo
`InventoryComponent` também não é a fonte do inventário persistente, que está em
`GameState.inventory`.

## Salvamentos

Perfis reais ficam em `user://saves/`, no diretório de dados do aplicativo definido
pelo Godot. Não são armazenados no repositório.

- Nomes inválidos e duplicados são rejeitados; excluir um perfil exige confirmação.
- Dados carregados são validados antes de substituir o perfil ativo.
- Chaves antigas `backpack` e `stash` são migradas em memória para `backpack_level`
  e `stash_items`. Um arquivo incompatível não é sobrescrito ao tentar carregá-lo.
- A gravação usa um arquivo temporário e renomeação para substituir o perfil
  somente depois da escrita. Falhas são retornadas para o chamador.
- Morte é salva antes da animação. Sair pela tela final tenta novamente uma
  gravação que tenha falhado.

## Verificação

Com o executável do Godot disponível no terminal:

```text
godot --headless --path . --editor --quit
godot --headless --path . res://Tests/run_tests.tscn
```

No Windows pode ser necessário usar o executável `Godot_*_console.exe` com seu
caminho completo. A suíte termina com código diferente de zero se houver falha.
Os testes criam perfis exclusivos em `.test-output/`; não carregam saves reais.
As animações e transições são exercitadas sem interface gráfica. Isso não substitui
uma avaliação visual de layout, áudio e desempenho no jogo aberto.

## Próximas etapas de design

1. Comprar espaços adicionais de mochila com moedas, como melhoria permanente.
   `backpack_level` já é persistido; preço, limite e botão de compra ainda não foram
   implementados. A capacidade atual é `2 + backpack_level` (3 espaços inicialmente).
2. Definir efeitos dos dados consumíveis e relíquias antes de colocá-los à venda.
3. Balancear classes, recompensas, dificuldade, custos e penalidades.
4. Definir objetivo de uma expedição e condições de vitória além de sobreviver.
5. Rever layouts e exportações em uma rodada de testes visuais.

Os executáveis antigos em `build/` não representam automaticamente o código atual.
Novas saídas de build e resultados de testes estão ignorados no Git. Os binários
que já eram versionados foram preservados; podem ser retirados do histórico de
trabalho numa limpeza específica de distribuição.
