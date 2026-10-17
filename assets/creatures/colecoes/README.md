# Coleções almáticas

24 modelos adicionados à Pipa Dex e ao catálogo de eventos. As quatro Souls anteriores permanecem disponíveis.

- Rios e lendas: Hiponilo, Marulume, Jarabrasa, Jaguarluar.
- Quatro Ventos: Azulongo, Auriflama, Umbrocasco, Nevagume (cauda corrigida, v2).
- Ventos Antigos: Rexal, Tricerafan, Pteralis, Stegaru.
- Almas dos Biomas: Guaravento, Micofolha, Capimansa, Tatutrama.
- Memórias do Vento: Yaguarú, Araruna, Tamoatá, Caimbira (raridade rara).
- Ecos Antigos: Herravento, Platofolha, Celofita, Riovela.

Artes e sprites gerados com image_gen a partir dos conceitos aprovados pelo usuário. Folhas RGBA originais preservadas, 4 × 4, cinco estados e 16 poses por modelo. Alguns contornos ainda têm resíduos semitransparentes; estes assets podem receber acabamento posterior sem alterar os IDs.

Os retângulos reais e tempos estão em assets/atlas.json. meta.viewport é um enquadramento único por folha, calculado pela união das poses, para manter escala estável sem ampliar cada quadro separadamente. Imagens são carregadas sob demanda e servidas com hash de conteúdo.

As classes de combate existentes continuam definidas por color (0 a 3); não foram criados novos poderes com base nos gestos dos sprites. A aparência equipável vem do inventário validado no servidor.

005_soul_collections.sql registra os modelos. Concessões usam a função administrativa grant_event_soul, idempotente e vinculada à conta. A consulta da Dex não concede itens. As concessões do proprietário foram feitas separadamente no Supabase; nenhum identificador de conta foi inserido no cliente.
