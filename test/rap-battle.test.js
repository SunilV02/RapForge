import cds from '@sap/cds';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

const t = cds.test(join(__dirname, '..'));
t.defaults.auth = { username: 'admin', password: 'admin' };

describe('RapBattleService', () => {

    let GET, POST;

    beforeAll(async () => {
        await t.server;
        GET  = t.GET;
        POST = t.POST;
    });

    describe('Artists', () => {

        it('GET /Artists returns seeded artists', async () => {
            const { data } = await GET('/api/rap-battle/Artists');
            expect(data.value.length).toBeGreaterThanOrEqual(4);
        });

        it('GET /Artists returns correct fields', async () => {
            const { data } = await GET('/api/rap-battle/Artists');
            const artist = data.value[0];
            expect(artist).toHaveProperty('ID');
            expect(artist).toHaveProperty('name');
            expect(artist).toHaveProperty('stageName');
        });

        it('POST /Artists creates a new artist', async () => {
            const { status, data } = await POST('/api/rap-battle/Artists', {
                name: 'Test Artist',
                stageName: 'T-Test',
                city: 'Soweto',
                bio: 'Created in a test'
            });
            expect(status).toBe(201);
            expect(data.name).toBe('Test Artist');
            expect(data.ID).toBeDefined();
        });
    });

    describe('Battles', () => {

        it('GET /Battles returns seeded battles', async () => {
            const { data } = await GET('/api/rap-battle/Battles');
            expect(data.value.length).toBeGreaterThanOrEqual(2);
        });

        it('GET /Battles all have valid status values', async () => {
            const { data } = await GET('/api/rap-battle/Battles');
            const validStatuses = ['upcoming', 'ongoing', 'completed'];
            data.value.forEach(b => expect(validStatuses).toContain(b.status));
        });

        it('POST /Battles creates a new battle', async () => {
            const { status, data } = await POST('/api/rap-battle/Battles', {
                title: 'Test Battle 2026',
                venue: 'Test Venue',
                status: 'upcoming'
            });
            expect(status).toBe(201);
            expect(data.title).toBe('Test Battle 2026');
        });
    });

    describe('Votes', () => {

        let battleId, artistId;

        beforeAll(async () => {
            const { data: battles } = await GET('/api/rap-battle/Battles');
            const { data: artists } = await GET('/api/rap-battle/Artists');
            battleId = battles.value.find(b => b.status === 'ongoing')?.ID ?? battles.value[0].ID;
            artistId = artists.value[0].ID;

            await POST('/api/rap-battle/BattleParticipants', {
                battle_ID: battleId,
                artist_ID: artistId,
                score: 0
            });
        });

        it('POST /Votes creates a vote successfully', async () => {
            const { status, data } = await POST('/api/rap-battle/Votes', {
                battle_ID: battleId,
                artist_ID: artistId,
                voter: 'jest-voter-1',
                comment: 'Fire bars!'
            });
            expect(status).toBe(201);
            expect(data.voter).toBe('jest-voter-1');
        });

        it('POST /Votes blocks duplicate vote from same voter', async () => {
            await POST('/api/rap-battle/Votes', {
                battle_ID: battleId,
                artist_ID: artistId,
                voter: 'jest-voter-dup',
                comment: 'First vote'
            });
            await expect(
                POST('/api/rap-battle/Votes', {
                    battle_ID: battleId,
                    artist_ID: artistId,
                    voter: 'jest-voter-dup',
                    comment: 'Second vote'
                })
            ).rejects.toMatchObject({ response: { status: 409 } });
        });
    });
});
