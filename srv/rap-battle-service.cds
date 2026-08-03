using { rap.battle as db } from '../db/schema';

@impl: './rap-battle-service.ts'
@requires: 'authenticated-user'
service RapBattleService @(path: '/api/rap-battle') {

    // Viewers and above can read Artists
    @readonly
    @requires: 'Viewer'
    entity Artists      as projection on db.Artists;

    // Admins can create/edit Artists
    @requires: 'Admin'
    action createArtist(name: String, stageName: String, city: String, bio: String)
        returns { ID: UUID; name: String; stageName: String; city: String; };

    // Viewers and above can read Battles
    @readonly
    @requires: 'Viewer'
    entity Battles      as projection on db.Battles;

    // Viewers can read participants
    @readonly
    @requires: 'Viewer'
    entity BattleParticipants as projection on db.BattleParticipants;

    // Voters can read votes; casting is controlled in handler
    @readonly
    @requires: 'Viewer'
    entity Votes        as projection on db.Votes;

    // Only Voters can cast a vote
    @requires: 'Voter'
    action castVote(battleId: UUID, artistId: UUID, comment: String)
        returns { success: Boolean; message: String; };

    // Anyone authenticated can see the leaderboard
    @requires: 'Viewer'
    function getLeaderboard(battleId: UUID)
        returns array of {
            artistId   : UUID;
            artistName : String;
            totalVotes : Integer;
        };
}
