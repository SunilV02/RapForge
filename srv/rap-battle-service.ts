import cds from '@sap/cds';

export class RapBattleService extends cds.ApplicationService {

    async init() {

        const { Artists, Battles, Votes, BattleParticipants } = this.entities;

        // ── BEFORE handlers (validation) ──────────────────────────────────────

        // Prevent voting on a completed battle
        this.before('CREATE', Votes, async (req) => {
            const { battle_ID } = req.data;
            const battle = await SELECT.one.from(Battles).where({ ID: battle_ID });
            if (!battle) return req.error(404, `Battle ${battle_ID} not found`);
            if (battle.status === 'completed') {
                return req.error(400, 'Cannot vote on a completed battle');
            }
        });

        // Prevent duplicate vote from same voter in the same battle
        this.before('CREATE', Votes, async (req) => {
            const { battle_ID, artist_ID, voter } = req.data;
            if (!voter) return req.error(400, 'Voter name is required');
            const existing = await SELECT.one.from(Votes)
                .where({ battle_ID, artist_ID, voter });
            if (existing) {
                return req.error(409, `${voter} already voted for this artist in this battle`);
            }
        });

        // ── AFTER handlers (side effects) ─────────────────────────────────────

        // After a vote is cast, update the participant's score
        this.after('CREATE', Votes, async (vote) => {
            const voteCount = await SELECT`count(*) as total`
                .from(Votes)
                .where({ battle_ID: vote.battle_ID, artist_ID: vote.artist_ID });

            await UPDATE(BattleParticipants)
                .set({ score: voteCount[0].total })
                .where({ battle_ID: vote.battle_ID, artist_ID: vote.artist_ID });
        });

        // ── Custom ACTION: castVote ────────────────────────────────────────────

        this.on('castVote', async (req) => {
            const { battleId, artistId, comment } = req.data;
            const voter = req.user?.id ?? 'anonymous';

            // Validate battle exists and is active
            const battle = await SELECT.one.from(Battles).where({ ID: battleId });
            if (!battle) return { success: false, message: `Battle not found` };
            if (battle.status === 'completed') {
                return { success: false, message: 'Battle is already completed' };
            }

            // Validate artist is a participant
            const participant = await SELECT.one.from(BattleParticipants)
                .where({ battle_ID: battleId, artist_ID: artistId });
            if (!participant) {
                return { success: false, message: 'Artist is not in this battle' };
            }

            // Check for duplicate vote
            const duplicate = await SELECT.one.from(Votes)
                .where({ battle_ID: battleId, artist_ID: artistId, voter });
            if (duplicate) {
                return { success: false, message: 'You already voted for this artist' };
            }

            // Insert vote
            await INSERT.into(Votes).entries({
                battle_ID: battleId,
                artist_ID: artistId,
                voter,
                comment
            });

            return { success: true, message: 'Vote cast successfully!' };
        });

        // ── Custom FUNCTION: getLeaderboard ───────────────────────────────────

        this.on('getLeaderboard', async (req) => {
            const { battleId } = req.data;

            const results = await cds.run(
                SELECT.from(BattleParticipants)
                    .join(Artists).on('BattleParticipants.artist_ID = Artists.ID')
                    .columns(
                        'Artists.ID as artistId',
                        'Artists.name as artistName',
                        'BattleParticipants.score as totalVotes'
                    )
                    .where({ 'BattleParticipants.battle_ID': battleId })
                    .orderBy('BattleParticipants.score desc')
            );

            return results;
        });

        await super.init();
    }
}
