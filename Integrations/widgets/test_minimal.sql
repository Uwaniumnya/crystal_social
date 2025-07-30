-- Test file to isolate type mismatch issue
CREATE POLICY "Test policy 1"
ON stickers FOR SELECT
USING (auth.uid()::UUID = user_id);

CREATE POLICY "Test policy 2"  
ON message_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM message_bubbles 
        WHERE message_bubbles.message_id = message_reactions.message_id
        AND message_bubbles.user_id = auth.uid()::UUID
    )
);
