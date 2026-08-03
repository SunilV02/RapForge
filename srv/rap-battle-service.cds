using { rap.battle as db } from '../db/schema';

@impl: './rap-battle-service.ts'
@requires: 'authenticated-user'
service RapBattleService @(path: '/api/rap-battle') {

    @restrict: [
        { grant: 'READ',  to: 'Viewer' },
        { grant: 'WRITE', to: 'Admin'  }
    ]
    entity Artists      as projection on db.Artists;

    @restrict: [
        { grant: 'READ',  to: 'Viewer' },
        { grant: 'WRITE', to: 'Admin'  }
    ]
    entity Battles      as projection on db.Battles;

    @restrict: [
        { grant: 'READ',  to: 'Viewer' },
        { grant: 'WRITE', to: 'Admin'  }
    ]
    entity BattleParticipants as projection on db.BattleParticipants;

    @restrict: [
        { grant: 'READ',  to: 'Viewer' },
        { grant: 'WRITE', to: 'Voter'  }
    ]
    entity Votes        as projection on db.Votes;

    @requires: 'Voter'
    action castVote(battleId: UUID, artistId: UUID, comment: String)
        returns { success: Boolean; message: String; };

    @requires: 'Viewer'
    function getLeaderboard(battleId: UUID)
        returns array of {
            artistId   : UUID;
            artistName : String;
            totalVotes : Integer;
        };
}
