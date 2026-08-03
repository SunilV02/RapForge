using RapBattleService from '../../srv/rap-battle-service';

// ── List Report annotations ────────────────────────────────────────────────

annotate RapBattleService.Battles with @(

    UI.SelectionFields: [ status, date ],

    UI.LineItem: [
        { $Type: 'UI.DataField', Value: title,  Label: 'Title'  },
        { $Type: 'UI.DataField', Value: date,   Label: 'Date'   },
        { $Type: 'UI.DataField', Value: venue,  Label: 'Venue'  },
        {
            $Type      : 'UI.DataField',
            Value      : status,
            Label      : 'Status',
            Criticality: #Positive
        }
    ],

    // ── Object Page ──────────────────────────────────────────────────────────

    UI.HeaderInfo: {
        TypeName      : 'Battle',
        TypeNamePlural: 'Battles',
        Title         : { Value: title },
        Description   : { Value: venue }
    },

    UI.Facets: [
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Battle Info',
            Target: '@UI.FieldGroup#BattleInfo'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Participants',
            Target: 'participants/@UI.LineItem'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Votes',
            Target: 'votes/@UI.LineItem'
        }
    ],

    UI.FieldGroup #BattleInfo: {
        $Type : 'UI.FieldGroupType',
        Data  : [
            { $Type: 'UI.DataField', Value: title  },
            { $Type: 'UI.DataField', Value: date   },
            { $Type: 'UI.DataField', Value: venue  },
            { $Type: 'UI.DataField', Value: status }
        ]
    }
);

// ── Participants sub-table on Object Page ──────────────────────────────────

annotate RapBattleService.BattleParticipants with @(
    UI.LineItem: [
        { $Type: 'UI.DataField', Value: artist.name,      Label: 'Artist'    },
        { $Type: 'UI.DataField', Value: artist.stageName, Label: 'Stage Name'},
        { $Type: 'UI.DataField', Value: score,            Label: 'Votes'     }
    ]
);

// ── Votes sub-table on Object Page ────────────────────────────────────────

annotate RapBattleService.Votes with @(
    UI.LineItem: [
        { $Type: 'UI.DataField', Value: artist.name, Label: 'Artist' },
        { $Type: 'UI.DataField', Value: voter,       Label: 'Voter'  },
        { $Type: 'UI.DataField', Value: comment,     Label: 'Comment'}
    ]
);

// ── Value help for status filter ───────────────────────────────────────────

annotate RapBattleService.Battles with {
    status @(
        Common.ValueListWithFixedValues: true,
        Common.ValueList: {
            CollectionPath: 'Battles',
            Parameters: [{
                $Type            : 'Common.ValueListParameterOut',
                LocalDataProperty: status,
                ValueListProperty: 'status'
            }]
        }
    )
};
